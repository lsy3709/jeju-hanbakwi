"""블렌더로 판타지 지도풍 제주도 모델(glb)을 만드는 스크립트.

실행(저장소 맨 위 폴더, 블렌더 5 기준):
    blender --background --python tools/make_fantasy_jeju.py
재료: tools/jeju_height.json (python tools/make_jeju_heightmap.py 로 만듦), web/public/models/dolhareubang.glb
결과: web/public/models/fantasy_jeju.glb  (+ 눈으로 고쳐 볼 수 있는 tools/fantasy_jeju.blend)

만드는 순서: 실제 높이 자료로 땅을 세움 → 높이를 계단처럼 다듬고 과장 → 높이에 따라 색칠
            → 바다와 받침 → 나무 · 집 · 돌하르방 · 구름을 올림 → glb 로 내보내기

약속(웹의 web/src/lib/fantasyMap.ts 와 같아야 핀이 제자리에 섭니다)
- 가로(동서) 10, 세로(남북)는 실제 비율대로. 네모의 가운데가 원점.
- 블렌더에서는 X 가 동쪽, Y 가 북쪽, Z 가 위. glb 로 내보내면 Y 가 위, 북쪽은 -Z 가 됩니다.
"""
import json
import math
import random
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parent.parent
DATA = json.loads((ROOT / "tools" / "jeju_height.json").read_text(encoding="utf-8"))
STATUE = ROOT / "web" / "public" / "models" / "dolhareubang.glb"
OUT = ROOT / "web" / "public" / "models" / "fantasy_jeju.glb"
BLEND = ROOT / "tools" / "fantasy_jeju.blend"

WEST, EAST, SOUTH, NORTH = DATA["west"], DATA["east"], DATA["south"], DATA["north"]
COLS, ROWS, HEIGHTS = DATA["cols"], DATA["rows"], DATA["heights"]
SIZE_X = 10.0
MID_LAT = math.radians((SOUTH + NORTH) / 2)
SIZE_Y = SIZE_X * ((NORTH - SOUTH) * 110.9) / ((EAST - WEST) * 111.32 * math.cos(MID_LAT))
PEAK_M = 1950.0  # 한라산 높이(미터)
PEAK_Z = 1.25  # 모델에서의 한라산 높이 — 실제보다 여섯 배쯤 과장합니다
STEP = 0.055  # 계단 한 칸의 높이
SEA_Z = 0.0
random.seed(7)  # 나무 · 집의 자리를 매번 같게

# 높이(미터)에 따른 색: 모래 → 연두 들판 → 초록 → 숲 → 깊은 숲 → 바위 → 정상
BANDS = [
    (12, (0.91, 0.84, 0.62)),
    (140, (0.67, 0.81, 0.47)),
    (380, (0.50, 0.72, 0.36)),
    (850, (0.32, 0.57, 0.30)),
    (1300, (0.24, 0.45, 0.31)),
    (1700, (0.55, 0.54, 0.48)),
    (9999, (0.94, 0.93, 0.89)),
]


def to_xy(lng, lat):
    """경도 · 위도 → 모델의 X(동) · Y(북)."""
    return ((lng - WEST) / (EAST - WEST) - 0.5) * SIZE_X, ((lat - SOUTH) / (NORTH - SOUTH) - 0.5) * SIZE_Y


def meters_at(lng, lat):
    col = round((lng - WEST) / (EAST - WEST) * (COLS - 1))
    row = round((NORTH - lat) / (NORTH - SOUTH) * (ROWS - 1))
    return HEIGHTS[max(0, min(ROWS - 1, row))][max(0, min(COLS - 1, col))]


def to_z(meters):
    """실제 높이(미터) → 모델 높이. 과장하고 계단처럼 다듬습니다."""
    if meters <= 0:
        return -0.03  # 바다 밑(바다 면에 가려짐)
    smooth = PEAK_Z * (meters / PEAK_M) ** 0.8
    stepped = math.floor(smooth / STEP) * STEP
    return 0.04 + stepped * 0.75 + smooth * 0.25


def color_of(meters):
    for limit, rgb in BANDS:
        if meters < limit:
            shade = random.uniform(-0.025, 0.025)  # 살짝 얼룩지게
            return (rgb[0] + shade, rgb[1] + shade, rgb[2] + shade, 1.0)
    return (1, 1, 1, 1)


def material(name, rgb=None, vertex_color=False, roughness=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Roughness"].default_value = roughness
    if vertex_color:
        node = mat.node_tree.nodes.new("ShaderNodeVertexColor")
        node.layer_name = "Color"
        mat.node_tree.links.new(node.outputs["Color"], shader.inputs["Base Color"])
    else:
        shader.inputs["Base Color"].default_value = (*rgb, 1.0)
    return mat


def add_mesh(name, verts, faces, mat, colors=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    if colors:
        layer = mesh.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="POINT")
        for i, rgba in enumerate(colors):
            layer.data[i].color = rgba
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def build_terrain():
    verts, colors = [], []
    for r in range(ROWS):
        for c in range(COLS):
            x = (c / (COLS - 1) - 0.5) * SIZE_X
            y = (0.5 - r / (ROWS - 1)) * SIZE_Y  # 첫 줄이 북쪽
            verts.append((x, y, to_z(HEIGHTS[r][c])))
            colors.append(color_of(max(HEIGHTS[r][c], 1)))
    faces = []
    for r in range(ROWS - 1):
        for c in range(COLS - 1):
            # 네 귀퉁이가 모두 바다인 칸은 만들지 않습니다(파일이 작아지고 해안선이 또렷해짐).
            if max(HEIGHTS[r][c], HEIGHTS[r][c + 1], HEIGHTS[r + 1][c], HEIGHTS[r + 1][c + 1]) > 0:
                a = r * COLS + c
                faces.append((a, a + COLS, a + COLS + 1, a + 1))
    return add_mesh("terrain", verts, faces, material("land", vertex_color=True), colors)


def build_sea_and_base():
    w, h = SIZE_X / 2 + 0.6, SIZE_Y / 2 + 0.6
    sea = add_mesh("sea", [(-w, -h, SEA_Z), (w, -h, SEA_Z), (w, h, SEA_Z), (-w, h, SEA_Z)], [(0, 1, 2, 3)],
                   material("sea", (0.30, 0.66, 0.72), roughness=0.35))
    # 지도를 올려 둔 나무 받침(탁자 위의 지도처럼)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.16))
    base = bpy.context.object
    base.name = "base"
    base.scale = (w * 2 + 0.3, h * 2 + 0.3, 0.3)
    base.data.materials.append(material("wood", (0.55, 0.40, 0.24)))
    return sea, base


def cone(location, radius, height, sides, mat, name):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius, radius2=0, depth=height,
                                    location=(location[0], location[1], location[2] + height / 2))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def join(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    bpy.context.object.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return bpy.context.object


def build_trees():
    """숲 높이(300 ~ 1200m)의 칸 가운데 일부에 뾰족한 나무를 세웁니다."""
    green = material("tree", (0.16, 0.40, 0.24))
    spots = [(r, c) for r in range(ROWS) for c in range(COLS) if 300 < HEIGHTS[r][c] < 1200]
    trees = []
    for r, c in random.sample(spots, 230):
        x = (c / (COLS - 1) - 0.5) * SIZE_X + random.uniform(-0.02, 0.02)
        y = (0.5 - r / (ROWS - 1)) * SIZE_Y + random.uniform(-0.02, 0.02)
        size = random.uniform(0.8, 1.3)
        trees.append(cone((x, y, to_z(HEIGHTS[r][c])), 0.045 * size, 0.15 * size, 5, green, "tree"))
    return join(trees, "trees")


def build_houses():
    """마을 자리에 주황 지붕 집을 놓습니다(감귤 오렌지 — 서비스의 대표 색)."""
    wall = material("wall", (0.96, 0.93, 0.86))
    roof = material("roof", (0.95, 0.42, 0.11))
    towns = [(126.53, 33.50, 6), (126.56, 33.25, 5), (126.92, 33.44, 3), (126.26, 33.41, 3), (126.25, 33.23, 2),
             (126.80, 33.55, 2), (126.72, 33.31, 2)]
    parts = []
    for lng, lat, count in towns:
        for _ in range(count):
            hx, hy = lng + random.uniform(-0.035, 0.035), lat + random.uniform(-0.02, 0.02)
            meters = meters_at(hx, hy)
            if meters <= 0:
                continue
            x, y = to_xy(hx, hy)
            z = to_z(meters)
            bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z + 0.035))
            box = bpy.context.object
            box.scale = (0.09, 0.07, 0.07)
            box.rotation_euler = (0, 0, random.uniform(0, math.pi))
            box.data.materials.append(wall)
            parts.append(box)
            parts.append(cone((x, y, z + 0.07), 0.075, 0.06, 4, roof, "roof"))
            parts[-1].rotation_euler = (0, 0, box.rotation_euler[2] + math.pi / 4)
    return join(parts, "houses")


def build_statues():
    """돌하르방 모델(다른 스크립트로 만든 glb)을 불러와 다섯 곳에 세웁니다."""
    places = [(126.50, 33.49), (126.57, 33.26), (126.90, 33.46), (126.30, 33.38), (126.75, 33.38)]
    statues = []
    for lng, lat in places:
        bpy.ops.import_scene.gltf(filepath=str(STATUE))
        obj = bpy.context.selected_objects[0]
        x, y = to_xy(lng, lat)
        obj.location = (x, y, to_z(meters_at(lng, lat)))
        obj.scale = (0.34, 0.34, 0.34)
        obj.rotation_euler = (math.radians(90), 0, 0)  # glb 는 Y 가 위라 불러오면 세워 줘야 합니다
        statues.append(obj)
    return join(statues, "statues")


def build_clouds():
    white = material("cloud", (1.0, 1.0, 1.0), roughness=0.9)
    puffs = []
    for cx, cy in [(-3.2, 1.6), (-1.0, -2.2), (1.6, 2.3), (3.4, -0.9), (0.4, 0.3), (-3.9, -1.5)]:
        height = random.uniform(1.65, 2.0)
        for i in range(3):
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.2, 0.3),
                                                  location=(cx + i * 0.26 - 0.26, cy + random.uniform(-0.08, 0.08), height))
            puff = bpy.context.object
            puff.scale = (1.0, 0.8, 0.55)
            puff.data.materials.append(white)
            puffs.append(puff)
    return join(puffs, "clouds")


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    terrain = build_terrain()
    build_sea_and_base()
    build_trees()
    build_houses()
    build_statues()
    build_clouds()
    print(f"땅 {len(terrain.data.vertices)}점 {len(terrain.data.polygons)}면 · 크기 {SIZE_X:.3f} × {SIZE_Y:.3f}")
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=False, export_apply=True)
    print(f"만들었어요: {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()

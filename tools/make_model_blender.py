"""블렌더로 돌하르방 모델(glb)을 만드는 스크립트.

실행(저장소 맨 위 폴더, 블렌더 5 기준):
    blender --background --python tools/make_model_blender.py
결과: web/public/models/dolhareubang.glb  (+ 눈으로 고쳐 볼 수 있는 tools/dolhareubang.blend)

블렌더 화면에서 손으로 하는 일(도형 추가 → 크기 · 위치 조절 → 합치기 → 재질 → glTF 내보내기)을
그대로 코드로 적었습니다. 화면에서 직접 만들 때의 순서는 교안 D3 의 "블렌더 시범"에 있습니다.

약속: 모델의 바닥이 원점, 키가 1미터. 블렌더는 Z 가 위지만 glTF 로 내보낼 때 Y 가 위로 바뀝니다.
"""
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "web" / "public" / "models" / "dolhareubang.glb"
BLEND = ROOT / "tools" / "dolhareubang.blend"


def clear_scene():
    """새 파일의 기본 물체(상자 · 조명 · 카메라)를 지웁니다."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def sphere(name, location, scale):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return obj


def cylinder(name, location, radius, depth, top_scale=1.0):
    """원기둥. top_scale 로 위쪽을 좁히면 모자처럼 됩니다."""
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=radius, radius2=radius * top_scale, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    return obj


def build():
    parts = [
        cylinder("받침", (0, 0, 0.025), 0.29, 0.05),
        # 몸통은 위로 갈수록 살짝 좁아지는 기둥, 어깨는 둥글게
        cylinder("몸통", (0, 0, 0.29), 0.25, 0.48, top_scale=0.86),
        sphere("어깨", (0, 0, 0.52), (0.215, 0.20, 0.10)),
        sphere("머리", (0, 0, 0.67), (0.20, 0.19, 0.17)),
        # 벙거지 모자: 납작한 챙 위에 둥근 머리 부분
        cylinder("모자 챙", (0, 0, 0.805), 0.235, 0.03),
        sphere("모자", (0, 0, 0.83), (0.19, 0.19, 0.17)),
        # 얼굴: 돌하르방의 특징인 툭 튀어나온 큰 눈, 넓적한 코, 다문 입
        sphere("왼눈", (-0.085, -0.165, 0.71), (0.058, 0.035, 0.045)),
        sphere("오른눈", (0.085, -0.165, 0.71), (0.058, 0.035, 0.045)),
        sphere("코", (0, -0.185, 0.645), (0.055, 0.045, 0.075)),
        sphere("입", (0, -0.178, 0.575), (0.075, 0.02, 0.014)),
        # 배 위에 얹은 두 손(한 손은 위, 한 손은 아래)
        sphere("왼손", (-0.07, -0.225, 0.40), (0.14, 0.035, 0.04)),
        sphere("오른손", (0.07, -0.235, 0.28), (0.14, 0.035, 0.04)),
    ]
    parts[-2].rotation_euler = (0, math.radians(-12), 0)
    parts[-1].rotation_euler = (0, math.radians(12), 0)

    # 여러 도형을 하나로 합칩니다(화면에서는 모두 고르고 Ctrl+J).
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[1]  # 몸통을 기준으로 합칩니다
    bpy.ops.object.join()
    statue = bpy.context.object
    statue.name = "dolhareubang"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth()

    # 현무암 재질: 어두운 회색, 거칠고 금속성 없음
    basalt = bpy.data.materials.new("basalt")
    basalt.use_nodes = True
    shader = basalt.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (0.11, 0.115, 0.13, 1.0)
    shader.inputs["Roughness"].default_value = 0.95
    shader.inputs["Metallic"].default_value = 0.0
    statue.data.materials.clear()
    statue.data.materials.append(basalt)
    return statue


def main():
    clear_scene()
    statue = build()
    height = statue.dimensions.z
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # 파일 하나(glb)로 내보냅니다. 화면에서는 File → Export → glTF 2.0, Format 을 "glTF Binary (.glb)".
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=False, export_apply=True)
    print(f"만들었어요: {OUT} ({OUT.stat().st_size} bytes), 키 {height:.3f}m")


if __name__ == "__main__":
    main()

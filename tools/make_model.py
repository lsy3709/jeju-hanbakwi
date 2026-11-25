"""돌하르방 모양의 3D 모델(glb)을 만드는 스크립트 — 파이썬 기본 기능만 씁니다.

실행(저장소 맨 위 폴더):  python tools/make_model.py
결과: web/public/models/dolhareubang.glb

만드는 방법: 옆모습의 윤곽선(반지름, 높이)을 세로축 둘레로 한 바퀴 돌려 면을 만듭니다(물레 방식).
블렌더에서 직접 만든 모델로 바꾸려면 같은 이름의 glb 로 내보내 덮어쓰면 됩니다. 모델은 Y 축이 위, 높이 1(미터)입니다.
"""
import json
import math
import struct
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "web" / "public" / "models" / "dolhareubang.glb"
SEGMENTS = 32  # 한 바퀴를 몇 조각으로 나눌지

# 옆모습 윤곽선 (반지름, 높이) — 아래에서 위로. 받침 → 몸통 → 어깨 → 목 → 얼굴 → 모자 챙 → 모자
PROFILE = [
    (0.00, 0.00), (0.30, 0.00), (0.30, 0.05), (0.26, 0.07),
    (0.27, 0.30), (0.26, 0.48), (0.20, 0.55), (0.17, 0.58),
    (0.21, 0.63), (0.23, 0.72), (0.21, 0.80), (0.27, 0.82),
    (0.27, 0.85), (0.19, 0.87), (0.17, 0.96), (0.10, 1.00), (0.00, 1.00),
]


def build():
    positions, normals, indices = [], [], []
    for i, (r, y) in enumerate(PROFILE):
        # 윤곽선의 기울기에서 바깥쪽 방향(법선)을 구합니다. 빛을 받는 방향을 정하는 값입니다.
        r0, y0 = PROFILE[max(i - 1, 0)]
        r1, y1 = PROFILE[min(i + 1, len(PROFILE) - 1)]
        nr, ny = (y1 - y0), -(r1 - r0)
        length = math.hypot(nr, ny) or 1.0
        nr, ny = nr / length, ny / length
        for s in range(SEGMENTS + 1):
            a = 2 * math.pi * s / SEGMENTS
            positions.append((r * math.cos(a), y, r * math.sin(a)))
            normals.append((nr * math.cos(a), ny, nr * math.sin(a)))
    ring = SEGMENTS + 1
    for i in range(len(PROFILE) - 1):
        for s in range(SEGMENTS):
            a, b = i * ring + s, (i + 1) * ring + s
            indices += [a, b, a + 1, a + 1, b, b + 1]
    return positions, normals, indices


def main():
    positions, normals, indices = build()
    pos_bin = b"".join(struct.pack("<3f", *p) for p in positions)
    nor_bin = b"".join(struct.pack("<3f", *n) for n in normals)
    idx_bin = struct.pack(f"<{len(indices)}H", *indices)
    idx_bin += b"\x00" * (-len(idx_bin) % 4)
    blob = pos_bin + nor_bin + idx_bin
    xs, ys, zs = zip(*positions)
    gltf = {
        "asset": {"version": "2.0", "generator": "jeju-hanbakwi tools/make_model.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "dolhareubang"}],
        "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1}, "indices": 2, "material": 0}]}],
        # 현무암 색(docs/design.md 의 차콜에 가까운 회색). 거칠고 금속성 없음
        "materials": [{"name": "basalt", "doubleSided": True, "pbrMetallicRoughness": {
            "baseColorFactor": [0.36, 0.37, 0.40, 1.0], "metallicFactor": 0.0, "roughnessFactor": 0.95}}],
        "buffers": [{"byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": len(pos_bin), "target": 34962},
            {"buffer": 0, "byteOffset": len(pos_bin), "byteLength": len(nor_bin), "target": 34962},
            {"buffer": 0, "byteOffset": len(pos_bin) + len(nor_bin), "byteLength": len(idx_bin), "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(positions), "type": "VEC3",
             "min": [min(xs), min(ys), min(zs)], "max": [max(xs), max(ys), max(zs)]},
            {"bufferView": 1, "componentType": 5126, "count": len(normals), "type": "VEC3"},
            {"bufferView": 2, "componentType": 5123, "count": len(indices), "type": "SCALAR"},
        ],
    }
    text = json.dumps(gltf, separators=(",", ":")).encode()
    text += b" " * (-len(text) % 4)
    total = 12 + 8 + len(text) + 8 + len(blob)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<I4s", len(text), b"JSON") + text)
        f.write(struct.pack("<I4s", len(blob), b"BIN\x00") + blob)
    print(OUT, total, "bytes", len(positions), "점")


if __name__ == "__main__":
    main()

"""제주도의 높이 자료를 받아 작은 격자(JSON)로 정리합니다 — 판타지 지도 모델의 재료입니다.

실행(저장소 맨 위 폴더):  python tools/make_jeju_heightmap.py
결과: tools/jeju_height.json  (격자 한 칸의 값 = 그 자리의 높이, 미터. 바다는 0)

자료: AWS Terrain Tiles(키 필요 없음). 색으로 높이를 적어 둔 그림이라 아래 식으로 풉니다.
     높이(m) = 빨강 × 256 + 초록 + 파랑 ÷ 256 − 32768
필요한 것: Pillow (pip install pillow)
"""
import io
import json
import math
import urllib.request
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent / "jeju_height.json"
# 제주도를 담는 네모(우도 · 마라도 포함). 웹의 web/src/lib/fantasyMap.ts 와 같은 값이어야 합니다.
WEST, EAST, SOUTH, NORTH = 126.08, 127.02, 33.10, 33.62
COLS, ROWS = 180, 112  # 격자 크기(가로 × 세로)
ZOOM = 10
TILE = 256
URL = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"


def lng_to_px(lng):
    return (lng + 180) / 360 * (2**ZOOM) * TILE


def lat_to_px(lat):
    rad = math.radians(lat)
    return (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * (2**ZOOM) * TILE


def main():
    x0, x1 = int(lng_to_px(WEST) // TILE), int(lng_to_px(EAST) // TILE)
    y0, y1 = int(lat_to_px(NORTH) // TILE), int(lat_to_px(SOUTH) // TILE)
    sheet = Image.new("RGB", ((x1 - x0 + 1) * TILE, (y1 - y0 + 1) * TILE))
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            with urllib.request.urlopen(URL.format(z=ZOOM, x=x, y=y), timeout=30) as res:
                sheet.paste(Image.open(io.BytesIO(res.read())).convert("RGB"), ((x - x0) * TILE, (y - y0) * TILE))
            print("받음", x, y)
    pixels = sheet.load()
    rows = []
    for r in range(ROWS):
        lat = NORTH - (NORTH - SOUTH) * r / (ROWS - 1)  # 첫 줄이 북쪽
        row = []
        for c in range(COLS):
            lng = WEST + (EAST - WEST) * c / (COLS - 1)
            px = min(int(lng_to_px(lng) - x0 * TILE), sheet.width - 1)
            py = min(int(lat_to_px(lat) - y0 * TILE), sheet.height - 1)
            red, green, blue = pixels[px, py]
            row.append(max(0, round(red * 256 + green + blue / 256 - 32768)))
        rows.append(row)
    data = {"west": WEST, "east": EAST, "south": SOUTH, "north": NORTH, "cols": COLS, "rows": ROWS, "heights": rows}
    OUT.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
    top = max(max(row) for row in rows)
    land = sum(1 for row in rows for h in row if h > 0)
    print(f"만들었어요: {OUT} · 가장 높은 곳 {top}m · 땅 {land}칸 / 전체 {COLS * ROWS}칸")


if __name__ == "__main__":
    main()

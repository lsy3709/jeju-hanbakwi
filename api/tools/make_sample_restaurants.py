"""추천 식당 샘플(한식 · 해산물 · 고기구이 · 국수 · 카페)을 공개 지도에서 받아 정리합니다.

실행(api 폴더):  python -m tools.make_sample_restaurants          (받아 둔 파일이 있으면 그 경로를 뒤에 적습니다)
결과: api/data/sample_restaurants.json  — 넣을 때는  python -m tools.sync_spots --restaurants

자료: OpenStreetMap(오픈스트리트맵, © OpenStreetMap contributors, ODbL). 키가 필요 없습니다.
주의: 누구나 고치는 공개 지도라 문을 닫았거나 이름이 바뀐 곳이 섞여 있을 수 있습니다.
     "추천"은 맛을 평가했다는 뜻이 아니라, 여행지 가까이에서 골라 보여 준다는 뜻입니다. 수업용 샘플로만 씁니다.
"""

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from constants import FOOD_CATEGORIES
from tools.make_sample_places import BOX, clean_name, pick_evenly, usable
from tools.sync_spots import load_places, load_sample
from transform import FOOD_PHOTOS, area_by_position

OUT = Path(__file__).parent.parent / "data" / "sample_restaurants.json"
PER_CATEGORY = 20  # 분류마다 고를 수 → 다섯 분류 100곳
QUERY = f"""[out:json][timeout:90];
(
  nwr["amenity"~"^(restaurant|cafe)$"]["name"]{BOX};
);
out center tags;"""

# 분류를 정하는 규칙: (분류, 지도에 적힌 음식 종류, 이름에 있으면 확실한 낱말, 이름에 있으면 그럴 법한 낱말)
RULES = [
    ("고기구이", {"barbecue", "korean_bbq", "bbq"}, ["흑돼지", "갈비", "숯불", "삼겹", "깡통구이", "연탄구이"], ["구이"]),
    ("해산물", {"seafood", "fish", "sashimi"}, ["횟집", "회센터", "해녀", "갈치", "전복", "물회"], ["해물", "회마당"]),
    ("국수", {"noodle", "noodles"}, ["국수", "칼국수", "냉면", "밀면"], []),
    ("한식", {"korean", "regional"}, ["해장국", "국밥", "한정식", "한식당"], ["정식", "밥상", "식당", "백반"]),
]
# 이름에 이 낱말이 있으면 쓰지 않습니다(분류와 어긋나는 곳, 상표만 적힌 곳)
NEVER = ["치킨", "피자", "버거", "중국", "반점", "초밥", "스시", "돈까스", "분식", "PC", "노래", "주점", "호프", "구내",
         "다방", "뼈다귀", "닭갈비", "일식", "조개", "만화방", "순대", "설렁탕", "라면"]


def food_category(tags: dict, title: str) -> str | None:
    """지도 자료의 꼬리표와 이름으로 분류를 정합니다. 다섯 분류에 들지 않으면 None.

    순서: ① 카페 ② 이름의 확실한 낱말(흑돼지 · 횟집 · 국수 · 해장국 …) ③ 지도에 적힌 음식 종류 ④ 이름의 그럴 법한 낱말(식당 · 정식 …)
    지도에 '해산물'이라 적혀 있어도 이름이 '○○해장국'이면 한식으로 봅니다. 이름이 더 믿을 만했습니다.
    """
    if tags.get("amenity") == "cafe":
        return "카페"
    for category, _, sure, _ in RULES:
        if any(word in title for word in sure):
            return category
    kinds = {kind.strip() for kind in tags.get("cuisine", "").split(";") if kind.strip()}
    for category, cuisines, _, _ in RULES:
        if kinds & cuisines:
            return category
    if kinds:  # 음식 종류가 적혀 있는데 우리 분류가 아니면(피자 · 중식 …) 이름으로 넘겨짚지 않습니다
        return None
    for category, _, _, maybe in RULES:
        if any(word in title for word in maybe):
            return category
    return None


def drop_duplicates(items: list[dict], taken_titles: set[str] = frozenset()) -> list[dict]:
    """번호가 같거나, 띄어쓰기를 뺀 이름이 같은 곳은 처음 것만 남깁니다.

    taken_titles: 이미 DB 에 있는 여행지 · 편의 시설의 이름. 이것과 같은 이름도 뺍니다.
    """
    seen_ids: set[str] = set()
    seen_titles = {title.replace(" ", "") for title in taken_titles}
    kept = []
    for item in items:
        key = item["title"].replace(" ", "")
        if item["id"] in seen_ids or key in seen_titles:
            continue
        seen_ids.add(item["id"])
        seen_titles.add(key)
        kept.append(item)
    return kept


def fetch(saved: str | None) -> list[dict]:
    """공개 지도에서 받습니다. 받아 둔 파일을 주면 그 파일을 씁니다(지도 서버가 바쁠 때 502 가 나기도 합니다)."""
    if saved:
        return json.loads(Path(saved).read_text(encoding="utf-8"))
    request = urllib.request.Request(
        "https://overpass-api.de/api/interpreter",
        data=urllib.parse.urlencode({"data": QUERY}).encode(),
        headers={"User-Agent": "jeju-hanbakwi-sample-data"},
    )
    with urllib.request.urlopen(request, timeout=150) as response:
        return json.load(response)["elements"]


def main() -> int:
    elements = fetch(sys.argv[1] if len(sys.argv) > 1 else None)
    print(f"받은 곳 {len(elements)}건")

    candidates = []
    for element in elements:
        tags = element["tags"]
        title = clean_name(tags["name"])
        lat = element.get("lat") or element.get("center", {}).get("lat")
        lng = element.get("lon") or element.get("center", {}).get("lon")
        if lat is None or lng is None or not usable(title) or any(word in title for word in NEVER):
            continue
        category = food_category(tags, title)
        if category is None:
            continue
        address = " ".join(tags.get(key, "") for key in ("addr:city", "addr:district", "addr:street", "addr:housenumber")).strip()
        # 길 이름 없이 번지만 적힌 곳("23")은 주소로 쓸 수 없으니 지역 이름으로 대신합니다
        shown_address = address if tags.get("addr:street") or tags.get("addr:city") else area_by_position(lat, lng)
        candidates.append({
            "id": f"{element['type'][0]}{element['id']}",
            "title": title,
            "category": category,
            "area": area_by_position(lat, lng),
            "address": shown_address,
            "lat": round(lat, 6),
            "lng": round(lng, 6),
            "phone": tags.get("phone", ""),
            # 고르는 순서에만 쓰는 값: 주소나 전화가 적힌 곳(정보가 충실한 곳)을 먼저 넣습니다
            "rank": 0 if address or tags.get("phone") else 1,
        })

    taken = {spot["title"] for spot in load_sample()} | {place["title"] for place in load_places()}
    taken_ids = {place["id"] for place in load_places()}
    unique = [item for item in drop_duplicates(candidates, taken) if item["id"] not in taken_ids]
    print(f"쓸 수 있는 곳 {len(candidates)}건 → 중복을 빼고 {len(unique)}건")

    foods = []
    for category in FOOD_CATEGORIES:
        pool = [item for item in unique if item["category"] == category]
        chosen = pick_evenly(pool, PER_CATEGORY)
        print(f"- {category}: 후보 {len(pool)}곳 → {len(chosen)}곳 ({FOOD_PHOTOS[category]['file']})")
        foods.extend({key: value for key, value in food.items() if key != "rank"} for food in chosen)
    OUT.write_text(json.dumps(foods, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"만들었어요: {OUT} · {len(foods)}곳")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

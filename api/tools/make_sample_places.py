"""편의 시설 샘플(숙소 · 게스트하우스 · 병원 · 약국 · 편의점 · 교통)을 공개 지도에서 받아 정리합니다.

실행(api 폴더):  python -m tools.make_sample_places
결과: api/data/sample_places.json  — 넣을 때는  python -m tools.sync_spots --places

자료: OpenStreetMap(오픈스트리트맵, © OpenStreetMap contributors, ODbL). 키가 필요 없습니다.
주의: 누구나 고치는 공개 지도라 문을 닫았거나 이름이 바뀐 곳이 섞여 있을 수 있습니다. 수업용 샘플로만 씁니다.
"""

import json
import random
import re
import urllib.parse
import urllib.request
from pathlib import Path

from transform import PLACE_PHOTOS, area_by_position

OUT = Path(__file__).parent.parent / "data" / "sample_places.json"
BOX = "(33.10,126.08,33.62,127.02)"  # 제주도를 담는 네모(남, 서, 북, 동)
QUERY = f"""[out:json][timeout:90];
(
  nwr["tourism"~"^(hotel|motel|resort|guest_house|hostel)$"]["name"]{BOX};
  nwr["amenity"~"^(hospital|pharmacy|bus_station|ferry_terminal)$"]["name"]{BOX};
  nwr["shop"="convenience"]["name"]{BOX};
  nwr["aeroway"="aerodrome"]["name"]{BOX};
);
out center tags;"""

# 분류마다: 몇 곳을 고를지, 이름에 이 낱말이 있어야 함(엉뚱한 곳을 거르는 용도), 이 낱말이 있으면 뺌
RULES = {
    "숙소": (24, ["호텔", "리조트"], ["모텔", "찜질", "연회장"]),
    "게스트하우스": (20, ["게스트하우스", "호스텔"], ["찜질"]),
    "병원": (18, ["병원", "의원", "의료원"], ["동물", "관리실", "교정", "장의사"]),
    "약국": (20, ["약국"], ["편의점"]),
    "편의점": (24, ["CU", "GS25", "세븐일레븐", "이마트24", "편의점"], ["약국", "세탁", "CU 편의점"]),
    "교통": (14, ["공항", "터미널", "항"], ["나루터", "선착장", "포구"]),
}


def category_of(tags: dict) -> str:
    if tags.get("tourism") in ("hotel", "motel", "resort"):
        return "숙소"
    if tags.get("tourism") in ("guest_house", "hostel"):
        return "게스트하우스"
    if tags.get("amenity") == "hospital":
        return "병원"
    if tags.get("amenity") == "pharmacy":
        return "약국"
    if tags.get("shop") == "convenience":
        return "편의점"
    return "교통"


def clean_name(name: str) -> str:
    """공개 지도의 이름을 화면에 보일 이름으로 다듬습니다.

    '(주)오션그랜드호텔 (Ocean Grand Hotel)' → '오션그랜드호텔',  'JW Marriott … - JW 메리어트 제주 …' → 'JW 메리어트 제주 …'
    """
    name = re.sub(r"^\((주|사회복지법인|의료법인|재단법인)\)\s*", "", name.strip())
    if name.startswith("("):  # '(남양리조트) (( Namyangnijoteu ))' 처럼 이름이 괄호 안에 든 것
        name = name[1:].split(")")[0]
    name = name.split(" (")[0].split("(")[0].strip()
    if " - " in name:  # 영문 - 한글 을 함께 적은 것은 한글 쪽을 씁니다
        korean = [part for part in name.split(" - ") if re.search("[가-힣]", part)]
        name = korean[-1] if korean else name
    return name.strip()


def usable(title: str) -> bool:
    """한글이 두 글자 이상 든, 세 글자 이상의 이름만 씁니다('CU' 처럼 상표만 적힌 것은 뺌)."""
    return len(title) >= 3 and len(re.findall("[가-힣]", title)) >= 2


def pick_evenly(items: list[dict], count: int) -> list[dict]:
    """네 지역에서 번갈아 한 곳씩 골라, 한 지역에 몰리지 않게 합니다."""
    by_area: dict[str, list[dict]] = {}
    mixed = sorted(items, key=lambda it: it["title"])
    random.Random(7).shuffle(mixed)  # 가나다순으로만 고르면 한 상표에 몰립니다. 섞되, 다시 돌려도 같은 결과가 나오게 합니다
    mixed.sort(key=lambda it: it["rank"])  # 큰 병원처럼 먼저 넣고 싶은 곳을 앞으로
    for item in mixed:
        by_area.setdefault(item["area"], []).append(item)
    picked: list[dict] = []
    while len(picked) < count and any(by_area.values()):
        for area in ["제주시", "서귀포시", "동부", "서부"]:
            if by_area.get(area) and len(picked) < count:
                picked.append(by_area[area].pop(0))
    return picked


def main() -> int:
    request = urllib.request.Request(
        "https://overpass-api.de/api/interpreter",
        data=urllib.parse.urlencode({"data": QUERY}).encode(),
        headers={"User-Agent": "jeju-hanbakwi-sample-data"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        elements = json.load(response)["elements"]
    print(f"받은 곳 {len(elements)}건")

    found: dict[str, list[dict]] = {name: [] for name in RULES}
    seen: set[tuple[str, str]] = set()
    for element in elements:
        tags = element["tags"]
        category = category_of(tags)
        title = clean_name(tags["name"])
        _, must, never = RULES[category]
        lat = element.get("lat") or element.get("center", {}).get("lat")
        lng = element.get("lon") or element.get("center", {}).get("lon")
        if lat is None or lng is None or not usable(title) or (category, title) in seen:
            continue
        if not any(word in title for word in must) or any(word in title for word in never):
            continue
        seen.add((category, title))
        address = " ".join(tags.get(key, "") for key in ("addr:city", "addr:district", "addr:street", "addr:housenumber")).strip()
        found[category].append({
            "id": f"{element['type'][0]}{element['id']}",  # 공개 지도에서의 번호(같은 곳을 다시 넣어도 한 줄로 유지)
            "title": title,
            "category": category,
            "area": area_by_position(lat, lng),
            "address": address,
            "lat": round(lat, 6),
            "lng": round(lng, 6),
            "phone": tags.get("phone", ""),
            # 고르는 순서에만 쓰는 값: 병원 · 의료원 · 공항 · 터미널을 먼저 넣습니다
            "rank": 0 if any(word in title for word in ("병원", "의료원", "공항", "터미널")) else 1,
        })

    places = []
    for category, (count, _, _) in RULES.items():
        chosen = pick_evenly(found[category], count)
        print(f"- {category}: 후보 {len(found[category])}곳 → {len(chosen)}곳 ({PLACE_PHOTOS[category]['file']})")
        places.extend({key: value for key, value in place.items() if key != "rank"} for place in chosen)
    OUT.write_text(json.dumps(places, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"만들었어요: {OUT} · {len(places)}곳")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

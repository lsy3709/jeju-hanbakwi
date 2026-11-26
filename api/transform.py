"""외부 데이터(TourAPI) 한 건을 우리 DB 의 spots 한 줄로 바꿉니다.

원본에는 이름·주소·좌표·분류 번호만 있습니다.
여기서 우리 서비스에 필요한 값(분류 이름, 지역, 테마 태그, 실내/실외, 한 줄 소개)을 붙입니다.
=> "남의 데이터를 받아 내 서비스에 맞게 고친다"의 핵심 파일입니다.
"""

# 쓰는 곳: tools/sync_spots.py 가 TourAPI 에서 받은 원본을 to_spot_row 에 한 건씩 넣고, 나온 줄을 repo.upsert_spots 로 DB 에 넣습니다.
# 이 파일은 DB 도 네트워크도 부르지 않는 "순수한 규칙"이라 테스트하기 쉽습니다(tests/test_transform*.py).
# 낱말: 태그 = 관광지에 붙이는 테마 이름표(바다, 오름 …). 이름과 소개 글에 낱말이 들어 있는지로 붙입니다.
import re

# TourAPI 의 콘텐츠 유형 번호 → 우리 분류 이름. 여기에 없는 유형(숙박·여행코스 등)은 받지 않습니다.
CATEGORY_BY_TYPE = {
    "12": "관광지",
    "14": "문화시설",
    "15": "축제",
    "28": "레포츠",
    "38": "쇼핑",
    "39": "음식점",
}

# 주소에 이 이름이 있으면 동부/서부, 없으면 제주시/서귀포시 그대로.
EAST_TOWNS = ["구좌읍", "성산읍", "표선면", "우도면", "조천읍"]
WEST_TOWNS = ["한림읍", "한경면", "대정읍", "안덕면", "애월읍"]

# 테마 태그 규칙: 이름·소개 글에 낱말이 있으면 그 태그를 붙입니다.
THEME_KEYWORDS = {
    "바다": ["해수욕장", "해변", "해안", "바다", "포구", "등대", "섬", "코지", "항구"],
    "오름": ["오름", "일출봉", "분화구", "봉우리", "한라산", "산방산", "도두봉", "수월봉"],
    "숲": ["숲", "휴양림", "수목원", "곶자왈", "비자림", "삼나무"],
    "폭포": ["폭포"],
    "박물관": ["박물관", "미술관", "전시관", "뮤지엄", "기념관", "미디어아트"],
    "체험": ["체험", "테마파크", "카트", "레일바이크", "미로", "카약", "먹이 주기"],
    "카페": ["카페", "녹차", "디저트", "커피"],
    "시장": ["시장", "야시장", "오일장"],
    "역사": ["유적", "민속", "역사", "전설", "조선 시대", "성곽", "초가"],
    "아이와": ["아이와", "어린이", "가족", "아쿠아리움", "동물"],
    "사진": ["사진", "일출", "노을", "동백", "유채꽃", "수국", "핑크뮬리", "전망"],
    "드라이브": ["드라이브", "해안도로"],
}

# 실내로 보는 낱말. 문화시설(14)은 낱말이 없어도 실내로 봅니다.
INDOOR_KEYWORDS = ["실내", "박물관", "미술관", "전시관", "뮤지엄", "아쿠아리움", "동굴", "온실", "벙커", "지붕 덮인"]


# 규칙이 틀리는 곳을 바로잡는 표: 이름 → 고칠 것.
# 낱말 규칙은 편하지만 완벽하지 않습니다. 틀린 것을 발견하면 규칙을 복잡하게 만들기보다 여기에 한 줄 더합니다.
#   indoor       실내/실외를 이 값으로
#   remove_tags  잘못 붙은 태그 빼기
#   add_tags     빠진 태그 더하기
CORRECTIONS: dict[str, dict] = {
    "한림공원": {"indoor": False},  # 소개 글의 "용암동굴" 때문에 실내로 잡힘. 대부분 야외 정원
    "제주돌문화공원": {"indoor": False},  # "박물관" 때문에 실내로 잡힘. 넓은 야외 공원
    "새별오름": {"remove_tags": ["바다"]},  # "바다를 내려다볼 수 있다"는 문장 때문
    "금오름": {"remove_tags": ["바다"]},
    "산방산": {"remove_tags": ["바다"]},
    "흑돼지거리": {"remove_tags": ["시장"]},  # "동문시장과 가까워"라는 문장 때문
}


# 편의 시설의 분류별 대표 사진. 곳마다 사진을 구하기 어려워 분류마다 한 장을 함께 씁니다.
# 파일은 api/static/photos/places/ 에 있고(우리 서버가 내줌), 출처는 docs/photo-credits.md 에도 적혀 있습니다.
_COMMONS = "https://commons.wikimedia.org/wiki/File:"
PLACE_PHOTOS: dict[str, dict] = {
    "숙소": {"file": "places/lodging.jpg", "credit": "Abasaa · 퍼블릭 도메인 · Wikimedia Commons",
             "source_url": _COMMONS + "Ramada_Plaza_Jeju_Hotel.JPG"},
    "게스트하우스": {"file": "places/guesthouse.jpg",
                   "credit": "Korea.net / Korean Culture and Information Service · CC BY-SA 2.0 · Wikimedia Commons",
                   "source_url": _COMMONS + "KOCIS_Korea_Hanok_GuestHouse_01_(7596121988).jpg"},
    "병원": {"file": "places/hospital.jpg", "credit": "thddbwnd · CC BY 3.0 · Wikimedia Commons",
             "source_url": _COMMONS + "Jeju_National_University_Hospital_2.JPG"},
    "약국": {"file": "places/pharmacy.jpg", "credit": "Andrewssi2 · CC BY-SA 3.0 · Wikimedia Commons",
             "source_url": _COMMONS + "YakPharmacy.jpg"},
    "편의점": {"file": "places/store.jpg", "credit": "LandAndTree · CC0 · Wikimedia Commons",
               "source_url": _COMMONS + "GS25_Okcheon_Museong_Branch_20240730.jpg"},
    "교통": {"file": "places/transit.jpg", "credit": "제주특별자치도청 대중교통과 · 공공누리 제1유형 · Wikimedia Commons",
             "source_url": _COMMONS + "Island_Bus_Stop_and_Double-door_Bus_in_Jeju_City_Korea.jpg"},
}
# 추천 식당 분류별 대표 사진 (api/static/photos/places/food_*.jpg)
FOOD_PHOTOS: dict[str, dict] = {
    "한식": {"file": "places/food_korean.jpg", "credit": "egg (Hong, Yun Seon) · CC BY 2.0 · Wikimedia Commons",
             "source_url": _COMMONS + "Korean_cuisine-Hanjeongsik-03.jpg"},
    "해산물": {"file": "places/food_seafood.jpg", "credit": "littlepepper · CC0 · Wikimedia Commons",
               "source_url": _COMMONS + "Hoe_(raw_fish).jpg"},
    "고기구이": {"file": "places/food_bbq.jpg", "credit": "eommina · CC0 · Wikimedia Commons",
                 "source_url": _COMMONS + "Korean_BBQ.jpg"},
    "국수": {"file": "places/food_noodle.jpg", "credit": "신동혁 · CC0 · Wikimedia Commons",
             "source_url": _COMMONS + "Gogi-guksu.jpg"},
    "카페": {"file": "places/food_cafe.jpg", "credit": "Julius Schorzman · CC BY-SA 2.0 · Wikimedia Commons",
             "source_url": _COMMONS + "A_small_cup_of_coffee.JPG"},
}
# 분류별 한 줄 소개의 끝말과 실내 여부
_PLACE_WORDS = {"숙소": ("숙소", True), "게스트하우스": ("게스트하우스", True), "병원": ("병원", True),
                "약국": ("약국", True), "편의점": ("편의점", True), "교통": ("교통 시설", False),
                "한식": ("한식당", True), "해산물": ("해산물 식당", True), "고기구이": ("고기구이 식당", True),
                "국수": ("국수집", True), "카페": ("카페", True)}
_SIDE_PHOTOS = {**PLACE_PHOTOS, **FOOD_PHOTOS}


def area_by_position(lat: float, lng: float) -> str:
    """좌표로 지역을 정합니다. 공개 지도 자료에는 주소가 없는 곳이 많아, 주소 대신 위치로 나눕니다.

    서쪽 끝(한림 · 대정)과 동쪽 끝(구좌 · 성산)을 먼저 가르고, 가운데는 한라산을 기준으로 남북을 나눕니다.
    """
    if lng < 126.40:
        return "서부"
    if lng > 126.75:
        return "동부"
    return "제주시" if lat >= 33.38 else "서귀포시"


def to_place_row(raw: dict) -> dict | None:
    """편의 시설 · 추천 식당 한 건(tools/make_sample_places.py · make_sample_restaurants.py 가 만든 모양) → spots 한 줄. 쓸 수 없으면 None."""
    category = raw.get("category")
    title = _text(raw, "title")
    lat, lng = raw.get("lat"), raw.get("lng")
    if category not in _SIDE_PHOTOS or not title or lat is None or lng is None:
        return None
    word, indoor = _PLACE_WORDS[category]
    area = raw.get("area") or area_by_position(lat, lng)
    # 식당은 한 곳마다 다른 사진을 줍니다(tools/make_sample_restaurants.py 가 photo 를 붙임). 없으면 분류의 대표 사진.
    photo = raw.get("photo") or _SIDE_PHOTOS[category]
    phone = _text(raw, "phone")
    return {
        "source": "osm",  # OpenStreetMap
        "source_id": _text(raw, "id"),
        "title": title,
        "category": category,
        "area": area,
        "address": _text(raw, "address"),
        "lat": float(lat),
        "lng": float(lng),
        "image_url": "/photos/" + photo["file"],
        "image_credit": photo["credit"],
        "image_source_url": photo["source_url"],
        "overview": f"{area}에 있는 {word}입니다." + (f" 전화 {phone}" if phone else "") + (" 사진은 이 식당이 아니라 같은 종류 음식의 예시 사진입니다." if raw.get("photo") else " 사진은 분류를 대표하는 예시 사진입니다."),
        "one_liner": f"{area}의 {word}",
        "theme_tags": [],
        "indoor": indoor,
    }


def apply_corrections(row: dict, corrections: dict[str, dict] = CORRECTIONS) -> dict:
    """표에 이름이 있으면 그 줄을 고친 새 사전을 돌려줍니다. 없으면 그대로."""
    change = corrections.get(row["title"])
    if not change:
        return row
    # dict(row) 로 복사해서 고칩니다. 받은 원본 줄을 직접 바꾸면 부른 쪽 값이 몰래 달라지기 때문입니다.
    fixed = dict(row)
    if "indoor" in change:
        fixed["indoor"] = change["indoor"]
    tags = [tag for tag in row["theme_tags"] if tag not in change.get("remove_tags", [])]
    tags += [tag for tag in change.get("add_tags", []) if tag not in tags]
    fixed["theme_tags"] = tags
    return fixed


def _text(raw: dict, key: str) -> str:
    """값이 없거나 None 이어도 항상 글자로 돌려줍니다."""
    return str(raw.get(key) or "").strip()


def _number(raw: dict, key: str) -> float | None:
    """좌표는 글자("126.94")로 옵니다. 숫자로 바꾸고, 비었거나 이상하면 None."""
    try:
        value = float(_text(raw, key))
    except ValueError:
        return None
    # 원본은 좌표를 모를 때 0 을 넣어 보내므로, 0 도 "없음"으로 봅니다.
    return value if value != 0 else None


# 아래 pick_* 세 함수는 주소·글에서 낱말을 찾아 지역·태그·실내 여부를 정합니다. 순서가 중요한 곳은 pick_area 입니다.
# 동부/서부 마을 이름을 먼저 보고, 없을 때만 시 이름으로 나눕니다.
def pick_area(address: str) -> str:
    if any(town in address for town in EAST_TOWNS):
        return "동부"
    if any(town in address for town in WEST_TOWNS):
        return "서부"
    if "서귀포시" in address:
        return "서귀포시"
    return "제주시"


def pick_theme_tags(title: str, overview: str) -> list[str]:
    text = f"{title} {overview}"
    return [tag for tag, words in THEME_KEYWORDS.items() if any(word in text for word in words)]


def pick_indoor(content_type: str, title: str, overview: str) -> bool:
    if content_type == "14":
        return True
    text = f"{title} {overview}"
    return any(word in text for word in INDOOR_KEYWORDS)


def make_one_liner(overview: str, category: str, area: str) -> str:
    """소개 글의 첫 문장을 한 줄 소개로 씁니다. 소개 글이 없으면 분류와 지역으로 만듭니다."""
    # 마침표·느낌표·물음표 뒤의 공백에서 문장을 나누고 첫 문장만 씁니다. 너무 길면 60자로 줄입니다.
    first = re.split(r"(?<=[.!?。])\s+", overview.strip())[0] if overview.strip() else ""
    if not first:
        return f"{area}에서 만나는 {category}"
    return first if len(first) <= 60 else first[:59] + "…"


def to_spot_row(raw: dict, source: str = "tourapi") -> dict | None:
    """원본 한 건 → spots 한 줄. 받지 않는 유형이거나 이름이 없으면 None."""
    # 원본 필드 이름(contenttypeid, addr1, mapx …)은 TourAPI 가 정한 것이라 우리 이름과 다릅니다. 여기서 한 번만 바꿉니다.
    content_type = _text(raw, "contenttypeid")
    category = CATEGORY_BY_TYPE.get(content_type)
    title = _text(raw, "title")
    source_id = _text(raw, "contentid")
    if not category or not title or not source_id:
        return None

    address = _text(raw, "addr1")
    overview = re.sub(r"<[^>]+>", " ", _text(raw, "overview"))  # 원본 소개 글에는 <br> 같은 태그가 섞여 옵니다
    overview = re.sub(r"\s+", " ", overview).strip()
    area = pick_area(address)
    image = _text(raw, "firstimage").replace("http://", "https://")  # http 사진은 https 화면에서 막히므로 바꿔 둡니다

    row = {
        "source": source,
        "source_id": source_id,
        "title": title,
        "category": category,
        "area": area,
        "address": address,
        "lat": _number(raw, "mapy"),  # TourAPI 는 mapy = 위도, mapx = 경도
        "lng": _number(raw, "mapx"),
        "image_url": image or None,
        # 사진이 있을 때만 출처를 싣습니다. 출처가 따로 오지 않는 TourAPI 사진은 한국관광공사로 적습니다.
        "image_credit": (_text(raw, "image_credit") or ("한국관광공사" if source == "tourapi" else None)) if image else None,
        "image_source_url": (_text(raw, "image_source_url") or None) if image else None,
        "overview": overview,
        "one_liner": make_one_liner(overview, category, area),
        "theme_tags": pick_theme_tags(title, overview),
        "indoor": pick_indoor(content_type, title, overview),
    }
    return apply_corrections(row)  # 마지막에, 규칙이 틀린 곳을 표로 바로잡습니다

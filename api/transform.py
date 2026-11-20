"""외부 데이터(TourAPI) 한 건을 우리 DB 의 spots 한 줄로 바꿉니다.

원본에는 이름·주소·좌표·분류 번호만 있습니다.
여기서 우리 서비스에 필요한 값(분류 이름, 지역, 테마 태그, 실내/실외, 한 줄 소개)을 붙입니다.
=> "남의 데이터를 받아 내 서비스에 맞게 고친다"의 핵심 파일입니다.
"""

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


def apply_corrections(row: dict, corrections: dict[str, dict] = CORRECTIONS) -> dict:
    """표에 이름이 있으면 그 줄을 고친 새 사전을 돌려줍니다. 없으면 그대로."""
    change = corrections.get(row["title"])
    if not change:
        return row
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
    return value if value != 0 else None


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
    first = re.split(r"(?<=[.!?。])\s+", overview.strip())[0] if overview.strip() else ""
    if not first:
        return f"{area}에서 만나는 {category}"
    return first if len(first) <= 60 else first[:59] + "…"


def to_spot_row(raw: dict, source: str = "tourapi") -> dict | None:
    """원본 한 건 → spots 한 줄. 받지 않는 유형이거나 이름이 없으면 None."""
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

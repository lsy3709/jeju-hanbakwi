"""테스트용 가짜 DB. repo.SupabaseRepo 와 같은 함수를 메모리 안에서 흉내 냅니다."""


def make_spot(spot_id: int, title: str, category: str, area: str, theme_tags: list[str], indoor: bool) -> dict:
    """필드는 schemas.Spot 과 같습니다."""
    return {
        "id": spot_id,
        "title": title,
        "category": category,
        "area": area,
        "address": f"제주특별자치도 {title}",
        "lat": 33.4,
        "lng": 126.5,
        "image_url": None,
        "image_credit": None,
        "image_source_url": None,
        "overview": f"{title} 소개 글입니다.",
        "one_liner": f"{title} 한 줄 소개입니다.",
        "theme_tags": theme_tags,
        "indoor": indoor,
    }


# 테스트 안에 직접 적은 관광지 12건
SPOTS = [
    make_spot(1, "성산일출봉", "관광지", "동부", ["바다", "오름", "사진"], False),
    make_spot(2, "만장굴", "관광지", "동부", [], True),
    make_spot(3, "협재해수욕장", "관광지", "서부", ["바다", "아이와"], False),
    make_spot(4, "천지연폭포", "관광지", "서귀포시", ["숲", "폭포"], False),
    make_spot(5, "오설록 티뮤지엄", "문화시설", "서부", ["박물관", "카페"], True),
    make_spot(6, "아쿠아플라넷 제주", "문화시설", "동부", ["아이와"], True),
    make_spot(7, "국립제주박물관", "문화시설", "제주시", ["박물관", "체험", "역사", "아이와"], True),
    make_spot(8, "사려니숲길", "관광지", "동부", ["숲"], False),
    make_spot(9, "새별오름", "관광지", "서부", ["오름"], False),
    make_spot(10, "카멜리아힐", "관광지", "서부", ["사진"], False),
    make_spot(11, "동문재래시장", "쇼핑", "제주시", ["시장"], False),
    make_spot(12, "흑돼지거리", "음식점", "제주시", [], False),
]


class FakeRepo:
    def __init__(self):
        self.spots = [dict(spot) for spot in SPOTS]

    def list_spots(self, page=1, size=20):
        start = (page - 1) * size
        return self.spots[start : start + size], len(self.spots)

    def get_spot(self, spot_id):
        return next((s for s in self.spots if s["id"] == spot_id), None)

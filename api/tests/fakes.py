"""테스트용 가짜 DB. repo.SupabaseRepo 와 같은 함수를 메모리 안에서 흉내 냅니다."""

import json
from pathlib import Path

from transform import to_spot_row

SAMPLE = Path(__file__).parent.parent / "data" / "sample_spots.json"


class FakeRepo:
    def __init__(self):
        raw = json.loads(SAMPLE.read_text(encoding="utf-8"))
        self.spots = []
        for index, item in enumerate(raw, start=1):
            row = to_spot_row(item, source="sample")
            self.spots.append({"id": index, **row})
        self.favorites: list[tuple[str, int]] = []

    def list_spots(self, q=None, theme=None, area=None, category=None, indoor=None, page=1, size=20):
        items = self.spots
        if q:
            items = [s for s in items if q in s["title"] or q in s["one_liner"]]
        if theme:
            items = [s for s in items if theme in s["theme_tags"]]
        if area:
            items = [s for s in items if s["area"] == area]
        if category:
            items = [s for s in items if s["category"] == category]
        if indoor is not None:
            items = [s for s in items if s["indoor"] == indoor]
        start = (page - 1) * size
        return items[start : start + size], len(items)

    def get_spot(self, spot_id):
        return next((s for s in self.spots if s["id"] == spot_id), None)

    def list_favorites(self, user_id):
        ids = [spot_id for uid, spot_id in reversed(self.favorites) if uid == user_id]
        return [self.get_spot(i) for i in ids]

    def add_favorite(self, user_id, spot_id):
        if (user_id, spot_id) not in self.favorites:
            self.favorites.append((user_id, spot_id))

    def remove_favorite(self, user_id, spot_id):
        self.favorites = [f for f in self.favorites if f != (user_id, spot_id)]


def make_weather(first_day_rainy: bool):
    """4일치 가짜 날씨를 돌려주는 함수를 만듭니다. 첫날만 비가 오게 할 수 있습니다."""

    def get_weather():
        days = []
        for i in range(4):
            rainy = first_day_rainy and i == 0
            days.append(
                {
                    "date": f"2026-12-0{i + 1}",
                    "label": "비" if rainy else "맑음",
                    "icon": "rain" if rainy else "sun",
                    "temp_min": 8.0,
                    "temp_max": 13.0,
                    "rain_prob": 80 if rainy else 10,
                }
            )
        return {
            "rainy_today": first_day_rainy,
            "message": "테스트 날씨",
            "areas": [{"area": "제주시", "days": days}, {"area": "서귀포시", "days": days}],
        }

    return get_weather

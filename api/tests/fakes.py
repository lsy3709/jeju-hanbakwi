"""테스트용 가짜 DB. repo.SupabaseRepo 와 같은 함수를 메모리 안에서 흉내 냅니다."""

import json
from datetime import datetime, timezone
from pathlib import Path

from constants import SIDE_CATEGORIES
from transform import to_spot_row

SAMPLE = Path(__file__).parent.parent / "data" / "sample_spots.json"


class FakeRepo:
    def __init__(self):
        raw = json.loads(SAMPLE.read_text(encoding="utf-8"))
        self.spots = []
        for index, item in enumerate(raw, start=1):
            row = to_spot_row(item, source="sample")
            self.spots.append({"id": index, "hidden": False, **row})
        self.favorites: list[dict] = []      # {"id", "user_id", "spot_id"}
        self._favorite_id = 0
        self.trips: list[dict] = []
        self._trip_id = 0
        self.profiles: list[dict] = []       # {"no", "id", "email", "suspended", "created_at"}
        self.ai_usage: list[dict] = []       # ai_usage 표의 줄

    # ---------- 관광지 ----------
    def list_spots(self, q=None, theme=None, area=None, category=None, indoor=None,
                   after_id=None, size=20, include_hidden=False, hidden=None):
        items = self.spots
        if q:
            items = [s for s in items if q in s["title"] or q in s["one_liner"]]
        if theme:
            items = [s for s in items if theme in s["theme_tags"]]
        if area:
            items = [s for s in items if s["area"] == area]
        if category:
            items = [s for s in items if s["category"] == category]
        elif not include_hidden:
            items = [s for s in items if s["category"] not in SIDE_CATEGORIES]
        if indoor is not None:
            items = [s for s in items if s["indoor"] == indoor]
        if not include_hidden:
            items = [s for s in items if not s["hidden"]]
        elif hidden is not None:
            items = [s for s in items if s["hidden"] == hidden]
        if after_id is None:
            return items[:size], len(items)
        return [s for s in items if s["id"] > after_id][:size], None

    def upsert_spots(self, rows):
        """같은 원본(source, source_id)이 있으면 고치고, 없으면 새 번호로 넣습니다."""
        for row in rows:
            old = next((s for s in self.spots if (s["source"], s["source_id"]) == (row["source"], row["source_id"])), None)
            if old:
                old.update(row)
            else:
                self.spots.append({"id": max((s["id"] for s in self.spots), default=0) + 1, "hidden": False, **row})
        return len(rows)

    def list_by_categories(self, categories, limit=500):
        return [s for s in self.spots if s["category"] in categories and not s["hidden"]][:limit]

    def get_spot(self, spot_id, include_hidden=False):
        return next((s for s in self.spots if s["id"] == spot_id and (include_hidden or not s["hidden"])), None)

    def add_spot(self, row):
        spot = {"id": max(s["id"] for s in self.spots) + 1, "hidden": False, "image_credit": None, "image_source_url": None, **row}
        self.spots.append(spot)
        return spot

    def update_spot(self, spot_id, changes):
        spot = next((s for s in self.spots if s["id"] == spot_id), None)
        if spot is None:
            return None
        spot.update(changes)
        return spot

    # ---------- 찜 ----------
    def list_favorites(self, user_id, before_id=None, size=20):
        rows = [f for f in reversed(self.favorites) if f["user_id"] == user_id]
        if before_id is not None:
            rows = [f for f in rows if f["id"] < before_id]
        pairs = [(f["id"], self.get_spot(f["spot_id"])) for f in rows]
        return [(fid, spot) for fid, spot in pairs if spot][:size]

    def has_favorite(self, user_id, spot_id):
        return any(f["user_id"] == user_id and f["spot_id"] == spot_id for f in self.favorites)

    def add_favorite(self, user_id, spot_id):
        if not any(f["user_id"] == user_id and f["spot_id"] == spot_id for f in self.favorites):
            self._favorite_id += 1
            self.favorites.append({"id": self._favorite_id, "user_id": user_id, "spot_id": spot_id})

    def remove_favorite(self, user_id, spot_id):
        self.favorites = [f for f in self.favorites if not (f["user_id"] == user_id and f["spot_id"] == spot_id)]

    # ---------- 저장한 일정 ----------
    def list_trips(self, user_id, before_id=None, size=20):
        rows = [t for t in reversed(self.trips) if t["user_id"] == user_id]
        if before_id is not None:
            rows = [t for t in rows if t["id"] < before_id]
        return [self._public(t) for t in rows][:size]

    def add_trip(self, user_id, title, itinerary):
        self._trip_id += 1
        trip = {"id": self._trip_id, "user_id": user_id, "title": title, "itinerary": itinerary, "created_at": "2026-12-01T00:00:00+00:00"}
        self.trips.append(trip)
        return self._public(trip)

    def delete_trip(self, user_id, trip_id):
        before = len(self.trips)
        self.trips = [t for t in self.trips if not (t["user_id"] == user_id and t["id"] == trip_id)]
        return len(self.trips) < before

    @staticmethod
    def _public(trip):
        return {k: trip[k] for k in ("id", "title", "itinerary", "created_at")}

    # ---------- AI 사용량 ----------
    def add_ai_usage(self, row):
        self.ai_usage.append({"created_at": datetime.now(timezone.utc).isoformat(), **row})

    def list_ai_usage(self, since, user_id=None, limit=1000):
        rows = [r for r in self.ai_usage if datetime.fromisoformat(r["created_at"]) >= datetime.fromisoformat(since)]
        if user_id:
            rows = [r for r in rows if r["user_id"] == user_id]
        return list(reversed(rows))[:limit]

    def profile_emails(self, user_ids):
        return {p["id"]: p["email"] for p in self.profiles if p["id"] in user_ids}

    # ---------- 사용자 ----------
    def add_profile(self, user_id, email):
        """테스트에서 "가입한 사람"을 만드는 도우미. (진짜 DB 에서는 가입할 때 트리거가 넣습니다)"""
        row = {"no": len(self.profiles) + 1, "id": user_id, "email": email, "suspended": False, "created_at": "2026-12-01T00:00:00+00:00"}
        self.profiles.append(row)
        return row

    def is_suspended(self, user_id):
        return any(p["id"] == user_id and p["suspended"] for p in self.profiles)

    def _admin_row(self, profile):
        return {
            **profile,
            "favorite_count": sum(1 for f in self.favorites if f["user_id"] == profile["id"]),
            "trip_count": sum(1 for t in self.trips if t["user_id"] == profile["id"]),
        }

    def list_users(self, q=None, before_no=None, size=20):
        rows = list(reversed(self.profiles))
        if q:
            rows = [p for p in rows if q.lower() in (p["email"] or "").lower()]
        if before_no is not None:
            rows = [p for p in rows if p["no"] < before_no]
        return [self._admin_row(p) for p in rows][:size]

    def set_suspended(self, user_id, suspended):
        profile = next((p for p in self.profiles if p["id"] == user_id), None)
        if profile is None:
            return None
        profile["suspended"] = suspended
        return self._admin_row(profile)


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

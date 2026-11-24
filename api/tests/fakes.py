"""테스트용 가짜 DB. repo.SupabaseRepo 와 같은 함수를 메모리 안에서 흉내 냅니다."""

# 가짜 DB 가 있는 이유: 테스트가 진짜 Supabase 를 부르면 느리고, 키가 필요하고, 데이터가 오염됩니다.
# FakeRepo 는 repo.SupabaseRepo 와 같은 이름의 메서드를 갖추고 파이썬 목록(list)에 저장합니다. 테스트 한 번마다 새로 만들어져 서로 영향이 없습니다.
# 관광지 데이터는 api/data/sample_spots.json 을 transform 으로 고쳐 쓰므로 진짜 변환 규칙도 함께 검증됩니다.
import json
from datetime import datetime, timezone
from pathlib import Path

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
        # 진짜 repo 와 같은 조건 순서로 목록을 걸러 냅니다. 숨긴 곳 제외·커서 규칙도 똑같이 흉내 냅니다.
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
        if not include_hidden:
            items = [s for s in items if not s["hidden"]]
        elif hidden is not None:
            items = [s for s in items if s["hidden"] == hidden]
        if after_id is None:
            return items[:size], len(items)
        return [s for s in items if s["id"] > after_id][:size], None

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
        # 진짜 repo 처럼 user_id 가 같은 것만 고릅니다. 그래서 "남의 찜은 안 보인다" 테스트가 의미를 가집니다.
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

    # 앞의 밑줄(_)은 "이 파일 안에서만 쓰는 도우미"라는 관례입니다. user_id 를 빼고 돌려줍니다.
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


# 진짜 weather.get_weather 와 같은 모양의 값을 돌려주는 함수를 만들어 주는 함수입니다. 바깥 날씨 서비스를 부르지 않습니다.
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

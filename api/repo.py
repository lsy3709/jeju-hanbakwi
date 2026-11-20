"""DB(Supabase)에 묻고 답을 받아 오는 곳. (저장소 패턴)

서버의 다른 파일은 DB 를 직접 만지지 않고 여기 있는 함수만 부릅니다.
=> DB 가 바뀌어도 이 파일만 고치면 되고, 테스트에서는 가짜(tests/fakes.py)로 바꿔 끼울 수 있습니다.

다른 파일이 기대하는 함수는 아래가 전부입니다. 가짜 DB 도 이 이름과 모양만 맞추면 됩니다.
  list_spots(q, theme, area, category, indoor, page, size) → (목록, 전체 개수)
  get_spot(spot_id) → 한 곳 또는 None
  upsert_spots(rows) → 넣은 개수
  list_favorites(user_id) / add_favorite(user_id, spot_id) / remove_favorite(user_id, spot_id)
  list_trips(user_id) / add_trip(user_id, title, itinerary) / delete_trip(user_id, trip_id) → 지웠으면 True
"""

import re
from functools import lru_cache

from supabase import Client, create_client

from config import settings


@lru_cache
def get_client() -> Client:
    """Supabase 연결은 한 번만 만들어 계속 씁니다."""
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("api/.env 에 SUPABASE_URL 과 SUPABASE_SERVICE_ROLE_KEY 를 넣어 주세요.")
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def clean_search_word(q: str) -> str:
    """검색어에서 필터 문법에 쓰이는 기호를 지웁니다. (검색어로 필터를 조작하지 못하게)"""
    return re.sub(r"[^0-9A-Za-z가-힣ㄱ-ㅎ·\- ]", "", q).strip()[:30]


class SupabaseRepo:
    def __init__(self, client: Client):
        self.db = client

    # ---------- 관광지 ----------
    def list_spots(self, q=None, theme=None, area=None, category=None, indoor=None, page=1, size=20):
        """조건에 맞는 관광지와 전체 개수를 돌려줍니다. → (목록, 전체 개수)"""
        query = self.db.table("spots").select("*", count="exact")
        word = clean_search_word(q) if q else ""
        if word:
            # 이름 또는 한 줄 소개에 검색어가 들어 있는 것 (* 는 "아무 글자")
            query = query.or_(f"title.ilike.*{word}*,one_liner.ilike.*{word}*")
        if theme:
            query = query.contains("theme_tags", [theme])
        if area:
            query = query.eq("area", area)
        if category:
            query = query.eq("category", category)
        if indoor is not None:
            query = query.eq("indoor", indoor)
        start = (page - 1) * size
        result = query.order("id").range(start, start + size - 1).execute()
        return result.data, result.count or 0

    def get_spot(self, spot_id: int):
        result = self.db.table("spots").select("*").eq("id", spot_id).limit(1).execute()
        return result.data[0] if result.data else None

    def upsert_spots(self, rows: list[dict]) -> int:
        """같은 원본(source, source_id)이 이미 있으면 고치고, 없으면 새로 넣습니다."""
        if not rows:
            return 0
        result = self.db.table("spots").upsert(rows, on_conflict="source,source_id").execute()
        return len(result.data)

    # ---------- 찜 ----------
    def list_favorites(self, user_id: str):
        # favorites 와 연결된 spots 를 한 번에 가져옵니다.
        result = (
            self.db.table("favorites")
            .select("created_at, spots(*)")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return [row["spots"] for row in result.data if row.get("spots")]

    def add_favorite(self, user_id: str, spot_id: int) -> None:
        self.db.table("favorites").upsert(
            {"user_id": user_id, "spot_id": spot_id}, on_conflict="user_id,spot_id"
        ).execute()

    def remove_favorite(self, user_id: str, spot_id: int) -> None:
        self.db.table("favorites").delete().eq("user_id", user_id).eq("spot_id", spot_id).execute()

    # ---------- 저장한 일정 ----------
    # 모든 질의에 user_id 조건을 붙입니다. 서버는 비밀 키로 접속해 RLS 를 건너뛰므로,
    # "내 것만" 보이게 하는 책임은 이 조건에 있습니다.
    def list_trips(self, user_id: str):
        result = (
            self.db.table("trips")
            .select("id, title, itinerary, created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return result.data

    def add_trip(self, user_id: str, title: str, itinerary: list[dict]):
        result = (
            self.db.table("trips")
            .insert({"user_id": user_id, "title": title, "itinerary": itinerary})
            .execute()
        )
        row = result.data[0]
        return {k: row[k] for k in ("id", "title", "itinerary", "created_at")}

    def delete_trip(self, user_id: str, trip_id: int) -> bool:
        """지웠으면 True. 내 일정이 아니거나 없으면 False."""
        result = self.db.table("trips").delete().eq("user_id", user_id).eq("id", trip_id).execute()
        return bool(result.data)


def get_repo() -> SupabaseRepo:
    return SupabaseRepo(get_client())

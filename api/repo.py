"""DB(Supabase)에 묻고 답을 받아 오는 곳. (저장소 패턴)

서버의 다른 파일은 DB 를 직접 만지지 않고 여기 있는 함수만 부릅니다.
=> DB 가 바뀌어도 이 파일만 고치면 되고, 테스트에서는 가짜(tests/fakes.py)로 바꿔 끼울 수 있습니다.

다른 파일이 기대하는 함수는 아래가 전부입니다. 가짜 DB 도 이 이름과 모양만 맞추면 됩니다.
  list_spots(page, size) → (목록, 전체 개수)
  get_spot(spot_id) → 한 곳 또는 None
"""

from functools import lru_cache

from supabase import Client, create_client

from config import settings


@lru_cache
def get_client() -> Client:
    """Supabase 연결은 한 번만 만들어 계속 씁니다."""
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("api/.env 에 SUPABASE_URL 과 SUPABASE_SERVICE_ROLE_KEY 를 넣어 주세요.")
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


class SupabaseRepo:
    def __init__(self, client: Client):
        self.db = client

    # ---------- 관광지 ----------
    def list_spots(self, page=1, size=20):
        """관광지를 id 순서로 쪽을 나눠 돌려줍니다. → (목록, 전체 개수)"""
        query = self.db.table("spots").select("*", count="exact")
        start = (page - 1) * size
        result = query.order("id").range(start, start + size - 1).execute()
        return result.data, result.count or 0

    def get_spot(self, spot_id: int):
        result = self.db.table("spots").select("*").eq("id", spot_id).limit(1).execute()
        return result.data[0] if result.data else None


def get_repo() -> SupabaseRepo:
    return SupabaseRepo(get_client())

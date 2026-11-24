"""DB(Supabase)에 묻고 답을 받아 오는 곳. (저장소 패턴)

서버의 다른 파일은 DB 를 직접 만지지 않고 여기 있는 함수만 부릅니다.
=> DB 가 바뀌어도 이 파일만 고치면 되고, 테스트에서는 가짜(tests/fakes.py)로 바꿔 끼울 수 있습니다.

다른 파일이 기대하는 함수는 아래가 전부입니다. 가짜 DB 도 이 이름과 모양만 맞추면 됩니다.
  list_spots(q, theme, area, category, indoor, after_id, size, include_hidden, hidden) → (목록, 전체 개수 또는 None)
  get_spot(spot_id, include_hidden) → 한 곳 또는 None
  add_spot(row) / update_spot(spot_id, changes) → 한 줄 (없으면 None)
  upsert_spots(rows) → 넣은 개수
  list_favorites(user_id, before_id, size) → [(찜 번호, 관광지)] / has_favorite / add_favorite / remove_favorite
  list_trips(user_id, before_id, size) / add_trip(user_id, title, itinerary) / delete_trip(user_id, trip_id) → 지웠으면 True
  is_suspended(user_id) / list_users(q, before_no, size) / set_suspended(user_id, suspended)

목록은 모두 커서 방식입니다: "마지막으로 받은 줄의 번호"를 주면 그다음 묶음을 돌려줍니다.
"""

# 이 파일은 서버에서 DB 와 말하는 유일한 곳입니다. routers/ → services/ → repo.py 순으로 아래로만 부릅니다.
# 낱말: 커서 = "여기까지 봤다"는 표시(마지막 줄의 번호). 쪽 번호 대신 이것으로 다음 묶음을 받습니다.
# 낱말: RLS = DB 가 "이 사람은 이 줄만 볼 수 있다"를 스스로 지키는 규칙. 서버는 비밀 키로 이를 건너뛰므로 아래 질의가 직접 지킵니다.
import re
from functools import lru_cache

from supabase import Client, create_client

from config import settings


# lru_cache 는 "한 번 만든 결과를 기억해 두고 다음부터는 그대로 돌려준다"는 장치입니다.
@lru_cache
def get_client() -> Client:
    """Supabase 연결은 한 번만 만들어 계속 씁니다."""
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("api/.env 에 SUPABASE_URL 과 SUPABASE_SERVICE_ROLE_KEY 를 넣어 주세요.")
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def clean_email_word(q: str) -> str:
    """이메일 검색어에는 @ . _ - 까지만 더 허용합니다."""
    return re.sub(r"[^0-9A-Za-z@._\-]", "", q).strip()[:50]


def clean_search_word(q: str) -> str:
    """검색어에서 필터 문법에 쓰이는 기호를 지웁니다. (검색어로 필터를 조작하지 못하게)"""
    return re.sub(r"[^0-9A-Za-z가-힣ㄱ-ㅎ·\- ]", "", q).strip()[:30]


# DB 창구 하나. 가짜 DB(tests/fakes.py)도 같은 이름의 메서드를 갖춰 이 자리를 대신합니다.
class SupabaseRepo:
    def __init__(self, client: Client):
        self.db = client

    # ---------- 관광지 ----------
    def list_spots(self, q=None, theme=None, area=None, category=None, indoor=None,
                   after_id=None, size=20, include_hidden=False, hidden=None):
        """조건에 맞는 관광지를 번호(id) 작은 순으로 돌려줍니다. → (목록, 전체 개수)

        after_id 는 커서입니다. 주면 "그 번호 다음부터" size 개를 가져옵니다.
        쪽 번호(3쪽 = 앞의 40개를 건너뛰기)와 달리, 뒤로 갈수록 느려지지 않고
        중간에 줄이 더해지거나 빠져도 같은 줄을 두 번 주거나 건너뛰지 않습니다.
        전체 개수는 첫 묶음(after_id 없음)에서만 셉니다. 이어지는 묶음에서는 None 입니다.
        """
        first = after_id is None
        # 아래는 조건을 하나씩 덧붙여 DB 에 보낼 질문을 만드는 것입니다. execute() 를 부를 때 비로소 실제로 묻습니다.
        query = self.db.table("spots").select("*", count="exact" if first else None)
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
        if not include_hidden:
            query = query.eq("hidden", False)   # 관리자 화면이 아니면 숨긴 곳은 빼고
        elif hidden is not None:
            query = query.eq("hidden", hidden)
        if not first:
            query = query.gt("id", after_id)
        result = query.order("id").limit(size).execute()
        # 첫 묶음에서만 전체 개수를 돌려주고, 이어지는 묶음은 None (세는 데 시간이 들기 때문).
        return result.data, (result.count or 0) if first else None

    def get_spot(self, spot_id: int, include_hidden=False):
        query = self.db.table("spots").select("*").eq("id", spot_id)
        if not include_hidden:
            query = query.eq("hidden", False)
        result = query.limit(1).execute()
        return result.data[0] if result.data else None

    def add_spot(self, row: dict):
        return self.db.table("spots").insert(row).execute().data[0]

    def update_spot(self, spot_id: int, changes: dict):
        """고친 뒤의 한 줄을 돌려줍니다. 없는 번호면 None."""
        result = self.db.table("spots").update(changes).eq("id", spot_id).execute()
        return result.data[0] if result.data else None

    # upsert = update + insert. 데이터 가져오기 도구를 여러 번 돌려도 같은 곳이 중복으로 쌓이지 않게 합니다.
    def upsert_spots(self, rows: list[dict]) -> int:
        """같은 원본(source, source_id)이 이미 있으면 고치고, 없으면 새로 넣습니다."""
        if not rows:
            return 0
        result = self.db.table("spots").upsert(rows, on_conflict="source,source_id").execute()
        return len(result.data)

    # ---------- 찜 ----------
    def list_favorites(self, user_id: str, before_id=None, size=20):
        """최근에 찜한 순. → [(찜 번호, 관광지), ...]  before_id 는 커서(그 번호보다 먼저 찜한 것부터)."""
        # favorites 와 연결된 spots 를 한 번에 가져옵니다. 숨긴 곳은 뺍니다(!inner = 짝이 있는 것만).
        query = (
            self.db.table("favorites")
            .select("id, spots!inner(*)")
            .eq("user_id", user_id)
            .eq("spots.hidden", False)
        )
        if before_id is not None:
            query = query.lt("id", before_id)
        result = query.order("id", desc=True).limit(size).execute()
        return [(row["id"], row["spots"]) for row in result.data if row.get("spots")]

    def has_favorite(self, user_id: str, spot_id: int) -> bool:
        """이 한 곳을 찜했는가. 목록이 나뉘어 오므로 화면이 목록을 다 받아 찾지 않게 따로 묻습니다."""
        result = (
            self.db.table("favorites").select("spot_id").eq("user_id", user_id).eq("spot_id", spot_id).limit(1).execute()
        )
        return bool(result.data)

    def add_favorite(self, user_id: str, spot_id: int) -> None:
        # 이미 찜한 곳을 또 찜해도 오류 없이 한 줄만 남도록 upsert 를 씁니다.
        self.db.table("favorites").upsert(
            {"user_id": user_id, "spot_id": spot_id}, on_conflict="user_id,spot_id"
        ).execute()

    def remove_favorite(self, user_id: str, spot_id: int) -> None:
        # user_id 조건이 없으면 남의 찜까지 지울 수 있으니 반드시 함께 겁니다.
        self.db.table("favorites").delete().eq("user_id", user_id).eq("spot_id", spot_id).execute()

    # ---------- 저장한 일정 ----------
    # 모든 질의에 user_id 조건을 붙입니다. 서버는 비밀 키로 접속해 RLS 를 건너뛰므로,
    # "내 것만" 보이게 하는 책임은 이 조건에 있습니다.
    def list_trips(self, user_id: str, before_id=None, size=20):
        """최근에 저장한 순. before_id 는 커서(그 번호보다 먼저 저장한 것부터)."""
        query = self.db.table("trips").select("id, title, itinerary, created_at").eq("user_id", user_id)
        if before_id is not None:
            query = query.lt("id", before_id)
        return query.order("id", desc=True).limit(size).execute().data

    def add_trip(self, user_id: str, title: str, itinerary: list[dict]):
        result = (
            self.db.table("trips")
            .insert({"user_id": user_id, "title": title, "itinerary": itinerary})
            .execute()
        )
        row = result.data[0]
        # DB 가 돌려준 줄에서 화면에 필요한 칸만 골라 냅니다. (user_id 는 내보내지 않음)
        return {k: row[k] for k in ("id", "title", "itinerary", "created_at")}

    def delete_trip(self, user_id: str, trip_id: int) -> bool:
        """지웠으면 True. 내 일정이 아니거나 없으면 False."""
        # user_id 와 id 를 함께 걸어서, 남의 일정 번호를 알아도 지울 수 없습니다.
        result = self.db.table("trips").delete().eq("user_id", user_id).eq("id", trip_id).execute()
        return bool(result.data)

    # ---------- 사용자 (이용 정지 · 관리자 화면) ----------
    def is_suspended(self, user_id: str) -> bool:
        result = self.db.table("profiles").select("suspended").eq("id", user_id).limit(1).execute()
        return bool(result.data and result.data[0]["suspended"])

    def list_users(self, q=None, before_no=None, size=20):
        """최근에 가입한 순. 찜 수 · 일정 수는 admin_users 보기(view)가 한 번에 세어 줍니다."""
        query = self.db.table("admin_users").select("*")
        word = clean_email_word(q) if q else ""
        if word:
            query = query.ilike("email", f"*{word}*")
        if before_no is not None:
            query = query.lt("no", before_no)
        return query.order("no", desc=True).limit(size).execute().data

    def set_suspended(self, user_id: str, suspended: bool):
        """고친 뒤의 한 줄을 돌려줍니다. 없는 사용자면 None."""
        changed = self.db.table("profiles").update({"suspended": suspended}).eq("id", user_id).execute()
        # 고친 줄이 없다 = 그런 사용자가 없다. 호출한 쪽이 404 로 바꿉니다.
        if not changed.data:
            return None
        result = self.db.table("admin_users").select("*").eq("id", user_id).limit(1).execute()
        return result.data[0] if result.data else None

    # ---------- AI 사용량 ----------
    def add_ai_usage(self, row: dict) -> None:
        """일정 짜기 한 번을 한 줄로 적습니다. (요청 글 · 일정 내용 · 키는 적지 않습니다)"""
        self.db.table("ai_usage").insert(row).execute()

    def list_ai_usage(self, since: str, user_id: str | None = None, limit: int = 1000) -> list[dict]:
        """since(시각 글자) 뒤의 기록을 최근 것부터. user_id 를 주면 그 사람 것만."""
        query = (
            self.db.table("ai_usage")
            .select("user_id,mode,key_source,tokens_in,tokens_out,tokens_total,created_at")
            .gte("created_at", since)
        )
        if user_id:
            query = query.eq("user_id", user_id)
        return query.order("id", desc=True).limit(limit).execute().data

    def profile_emails(self, user_ids: list[str]) -> dict[str, str]:
        """사용자 번호 → 이메일. (사용량 표에 이름을 붙이는 데 씁니다)"""
        if not user_ids:
            return {}
        rows = self.db.table("profiles").select("id,email").in_("id", user_ids).execute().data
        return {row["id"]: row["email"] for row in rows}


# 주소들이 Depends(get_repo) 로 받아 가는 함수입니다. 테스트에서는 이 자리에 가짜 DB 를 끼웁니다.
def get_repo() -> SupabaseRepo:
    return SupabaseRepo(get_client())

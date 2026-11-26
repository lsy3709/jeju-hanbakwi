"""관리자만 쓰는 주소: 사용자 목록 · 이용 정지, 여행지 목록 · 추가 · 수정 · 숨김.

모든 주소에 get_admin_user 를 붙입니다(아래 router 의 dependencies).
관리자인지는 서버가 정합니다 — 환경변수 ADMIN_EMAILS 에 적힌 이메일로 로그인한 사람만 통과합니다.
화면에서 관리자 메뉴를 숨기는 것은 편의일 뿐이고, 막는 일은 여기서 합니다.

지우는 주소는 일부러 만들지 않았습니다. 사용자는 정지하고 여행지는 숨깁니다. 둘 다 되돌릴 수 있습니다.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from auth import get_admin_user
from constants import AREAS, CATEGORIES, PLACE_CATEGORIES, THEMES
from repo import get_repo
from schemas import AdminSpot, AdminSpotPage, AdminUser, AdminUserPage, AdminUserPatch, SpotCreate, SpotPatch, UsageReport, User
from services import usage
from services.paging import cut_page
from services.photos import with_photo_address, with_photo_addresses

router = APIRouter(prefix="/admin", tags=["관리자"], dependencies=[Depends(get_admin_user)])


# ---------------------------------------------------------------- 사용자

@router.get("/users", response_model=AdminUserPage)
def list_users(
    q: str | None = Query(default=None, max_length=50, description="이메일 일부"),
    cursor: int | None = Query(default=None, ge=0),
    size: int = Query(default=20, ge=1, le=50),
    repo=Depends(get_repo),
):
    rows = repo.list_users(q=q, before_no=cursor, size=size + 1)
    items, next_cursor = cut_page(rows, size, lambda row: row["no"])
    return {"items": items, "next_cursor": next_cursor}


@router.patch("/users/{user_id}", response_model=AdminUser)
def set_suspended(
    user_id: uuid.UUID,
    body: AdminUserPatch,
    admin: User = Depends(get_admin_user),
    repo=Depends(get_repo),
):
    # 관리자가 자기 자신을 정지하면 풀어 줄 사람이 없을 수 있어 막습니다.
    if body.suspended and str(user_id) == admin.id:
        raise HTTPException(status_code=400, detail="자기 자신은 정지할 수 없습니다.")
    row = repo.set_suspended(str(user_id), body.suspended)
    if row is None:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return row


# ---------------------------------------------------------------- 여행지

def check_choices(category: str | None, area: str | None, theme_tags: list[str] | None) -> None:
    """정해 둔 선택지(constants.py) 밖의 값이 들어오면 422. 화면의 필터와 어긋나지 않게 합니다."""
    if category is not None and category not in CATEGORIES + PLACE_CATEGORIES:
        raise HTTPException(status_code=422, detail="분류는 정해 둔 목록에서만 고를 수 있습니다.")
    if area is not None and area not in AREAS:
        raise HTTPException(status_code=422, detail="지역은 정해 둔 목록에서만 고를 수 있습니다.")
    if theme_tags is not None and any(tag not in THEMES for tag in theme_tags):
        raise HTTPException(status_code=422, detail="테마는 정해 둔 목록에서만 고를 수 있습니다.")


@router.get("/spots", response_model=AdminSpotPage)
def list_spots(
    request: Request,
    q: str | None = Query(default=None, max_length=50),
    hidden: bool | None = Query(default=None, description="true = 숨긴 곳만, false = 보이는 곳만"),
    cursor: int | None = Query(default=None, ge=0),
    size: int = Query(default=20, ge=1, le=50),
    repo=Depends(get_repo),
):
    rows, total = repo.list_spots(q=q, after_id=cursor, size=size + 1, include_hidden=True, hidden=hidden)
    items, next_cursor = cut_page(rows, size, lambda spot: spot["id"])
    return {"items": with_photo_addresses(items, request), "next_cursor": next_cursor, "total": total}


@router.post("/spots", response_model=AdminSpot, status_code=201)
def add_spot(body: SpotCreate, request: Request, repo=Depends(get_repo)):
    check_choices(body.category, body.area, body.theme_tags)
    row = body.model_dump()
    # 관리자가 손으로 넣은 곳은 source 를 admin 으로 적어, 받아 온 데이터(sample · tourapi)와 구분합니다.
    row.update({"source": "admin", "source_id": uuid.uuid4().hex})
    return with_photo_address(repo.add_spot(row), request)


@router.patch("/spots/{spot_id}", response_model=AdminSpot)
def update_spot(spot_id: int, body: SpotPatch, request: Request, repo=Depends(get_repo)):
    changes = body.model_dump(exclude_unset=True)   # 보낸 칸만
    if not changes:
        raise HTTPException(status_code=400, detail="고칠 내용이 없습니다.")
    if any(value is None for value in changes.values()):
        raise HTTPException(status_code=422, detail="빈 값(null)으로는 고칠 수 없습니다.")
    check_choices(changes.get("category"), changes.get("area"), changes.get("theme_tags"))
    row = repo.update_spot(spot_id, changes)
    if row is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    return with_photo_address(row, request)

# ---------------------------------------------------------------- AI 사용량

@router.get("/ai-usage", response_model=UsageReport)
def ai_usage(days: int = Query(default=30, ge=1, le=90), repo=Depends(get_repo)):
    """전체 사용량: 기간 합계 · 오늘 · 날짜별 · 사용자별(토큰을 많이 쓴 순)."""
    rows = usage.read_usage(repo, days)
    user_ids = sorted({row["user_id"] for row in rows if row["user_id"]})
    return usage.report(rows, days, emails=repo.profile_emails(user_ids))

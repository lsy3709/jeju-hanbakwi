"""로그인한 사람만 쓰는 주소: 내 정보, 찜, 저장한 일정.

get_current_user 가 토큰을 확인해 준 user.id 만 씁니다.
화면이 보낸 사용자 ID 는 받지 않습니다. (남의 ID 를 적어 보내면 남의 것을 볼 수 있게 되므로)
찜·일정 주소는 get_active_user 를 씁니다. 이용 정지된 계정이면 403 입니다.
목록은 커서 방식입니다(GET /spots 와 같은 약속).
"""

# 층: 이 파일(주소) → services/ 와 repo.py(DB). 모든 DB 질의에 user.id 를 넘겨, repo 가 "내 것만" 고르게 합니다.
# 낱말: 204 = 성공했지만 돌려줄 내용 없음(삭제 후), 201 = 새로 만들었음, 401 = 로그인 필요, 403 = 이용 정지, 404 = 없음.
# 낱말: get_current_user = 로그인만 확인, get_active_user = 로그인 + 이용 정지 아님까지 확인(auth.py).
from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response

from auth import get_active_user, get_current_user, is_admin
from repo import get_repo
from schemas import FavoriteIn, FavoritePage, Me, Trip, TripIn, TripPage, UsageReport, User
from services import usage
from services.paging import cut_page
from services.photos import with_photo_addresses

router = APIRouter(prefix="/me", tags=["내 정보"])


# GET /me : 로그인한 사람의 정보. 이용 정지 계정도 자기 상태를 알아야 하므로 get_current_user 를 씁니다.
@router.get("", response_model=Me)
def me(user: User = Depends(get_current_user), repo=Depends(get_repo)):
    return {"id": user.id, "email": user.email, "is_admin": is_admin(user), "suspended": repo.is_suspended(user.id)}


# ---------------------------------------------------------------- 찜

@router.get("/favorites", response_model=FavoritePage)
def list_favorites(
    request: Request,
    cursor: int | None = Query(default=None, ge=0),
    size: int = Query(default=20, ge=1, le=50),
    user: User = Depends(get_active_user),
    repo=Depends(get_repo),
):
    # user.id 는 토큰으로 서버가 확인한 값입니다. 화면이 보낸 값이 아니라 남의 찜을 볼 수 없습니다.
    rows = repo.list_favorites(user.id, before_id=cursor, size=size + 1)   # [(찜 번호, 관광지)]
    page, next_cursor = cut_page(rows, size, lambda row: row[0])
    return {"items": with_photo_addresses([spot for _, spot in page], request), "next_cursor": next_cursor}


@router.get("/favorites/{spot_id}")
def has_favorite(spot_id: int, user: User = Depends(get_active_user), repo=Depends(get_repo)):
    """상세 화면의 하트가 쓸 주소. 찜 목록은 나뉘어 오므로 "이 한 곳"은 따로 묻습니다."""
    return {"spot_id": spot_id, "favorite": repo.has_favorite(user.id, spot_id)}


@router.post("/favorites", status_code=201)
def add_favorite(body: FavoriteIn, user: User = Depends(get_active_user), repo=Depends(get_repo)):
    # 없는 관광지(또는 숨긴 곳)를 찜하지 못하게 먼저 확인합니다.
    if repo.get_spot(body.spot_id) is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    repo.add_favorite(user.id, body.spot_id)
    return {"spot_id": body.spot_id}


@router.delete("/favorites/{spot_id}", status_code=204)
def remove_favorite(spot_id: int, user: User = Depends(get_active_user), repo=Depends(get_repo)):
    repo.remove_favorite(user.id, spot_id)
    # 204 는 본문이 없어야 하므로 빈 Response 를 직접 돌려줍니다.
    return Response(status_code=204)


# ---------------------------------------------------------------- 내 AI 사용량

@router.get("/ai-usage", response_model=UsageReport)
def my_ai_usage(
    days: int = Query(default=30, ge=1, le=90),
    user: User = Depends(get_current_user),   # 이용 정지된 사람도 자기 사용량은 볼 수 있습니다
    repo=Depends(get_repo),
):
    return usage.report(usage.read_usage(repo, days, user_id=user.id), days)


# ---------------------------------------------------------------- 저장한 일정

@router.get("/trips", response_model=TripPage)
def list_trips(
    cursor: int | None = Query(default=None, ge=0),
    size: int = Query(default=20, ge=1, le=50),
    user: User = Depends(get_active_user),
    repo=Depends(get_repo),
):
    rows = repo.list_trips(user.id, before_id=cursor, size=size + 1)
    items, next_cursor = cut_page(rows, size, lambda trip: trip["id"])
    return {"items": items, "next_cursor": next_cursor}


@router.post("/trips", response_model=Trip, status_code=201)
def add_trip(body: TripIn, user: User = Depends(get_active_user), repo=Depends(get_repo)):
    # mode="json": 날짜 같은 값을 DB 에 넣을 수 있는 글자로 바꿉니다.
    itinerary = [day.model_dump(mode="json") for day in body.itinerary]
    return repo.add_trip(user.id, body.title, itinerary)


@router.delete("/trips/{trip_id}", status_code=204)
def delete_trip(trip_id: int, user: User = Depends(get_active_user), repo=Depends(get_repo)):
    # 남의 일정 번호를 보내도 repo 가 user_id 로 걸러 False 가 되므로, 있는지 없는지 구분하지 않고 404 를 냅니다.
    if not repo.delete_trip(user.id, trip_id):
        raise HTTPException(status_code=404, detail="저장한 일정을 찾을 수 없습니다.")
    return Response(status_code=204)

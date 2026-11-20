"""로그인한 사람만 쓰는 주소: 내 정보, 찜, 저장한 일정.

get_current_user 가 토큰을 확인해 준 user.id 만 씁니다.
화면이 보낸 사용자 ID 는 받지 않습니다. (남의 ID 를 적어 보내면 남의 것을 볼 수 있게 되므로)
"""

from fastapi import APIRouter, Depends, HTTPException, Request, Response

from auth import get_current_user
from repo import get_repo
from schemas import FavoriteIn, Spot, Trip, TripIn, User
from services.photos import with_photo_addresses

router = APIRouter(prefix="/me", tags=["내 정보"])


@router.get("", response_model=User)
def me(user: User = Depends(get_current_user)):
    return user


# ---------------------------------------------------------------- 찜

@router.get("/favorites", response_model=list[Spot])
def list_favorites(request: Request, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    return with_photo_addresses(repo.list_favorites(user.id), request)


@router.post("/favorites", status_code=201)
def add_favorite(body: FavoriteIn, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    if repo.get_spot(body.spot_id) is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    repo.add_favorite(user.id, body.spot_id)
    return {"spot_id": body.spot_id}


@router.delete("/favorites/{spot_id}", status_code=204)
def remove_favorite(spot_id: int, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    repo.remove_favorite(user.id, spot_id)
    return Response(status_code=204)


# ---------------------------------------------------------------- 저장한 일정

@router.get("/trips", response_model=list[Trip])
def list_trips(user: User = Depends(get_current_user), repo=Depends(get_repo)):
    return repo.list_trips(user.id)


@router.post("/trips", response_model=Trip, status_code=201)
def add_trip(body: TripIn, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    # mode="json": 날짜 같은 값을 DB 에 넣을 수 있는 글자로 바꿉니다.
    itinerary = [day.model_dump(mode="json") for day in body.itinerary]
    return repo.add_trip(user.id, body.title, itinerary)


@router.delete("/trips/{trip_id}", status_code=204)
def delete_trip(trip_id: int, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    if not repo.delete_trip(user.id, trip_id):
        raise HTTPException(status_code=404, detail="저장한 일정을 찾을 수 없습니다.")
    return Response(status_code=204)

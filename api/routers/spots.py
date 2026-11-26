"""관광지 주소: 선택지, 목록(검색·필터·커서 페이징), 상세. 누구나 볼 수 있습니다."""

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from constants import AREAS, CATEGORIES, FOOD_CATEGORIES, PLACE_CATEGORIES, THEMES
from repo import get_repo
from schemas import Meta, NearbySpot, Spot, SpotList
from services.nearby import nearest
from services.paging import cut_page
from services.photos import with_photo_address, with_photo_addresses

router = APIRouter(tags=["관광지"])


@router.get("/meta", response_model=Meta)
def meta():
    return {"themes": THEMES, "areas": AREAS, "categories": CATEGORIES,
            "place_categories": PLACE_CATEGORIES, "food_categories": FOOD_CATEGORIES}


@router.get("/spots", response_model=SpotList)
def list_spots(
    request: Request,
    q: str | None = Query(default=None, max_length=50),
    theme: str | None = None,
    area: str | None = None,
    category: str | None = None,
    indoor: bool | None = None,
    cursor: int | None = Query(default=None, ge=0, description="앞 응답의 next_cursor. 없으면 처음부터"),
    size: int = Query(default=20, ge=1, le=50),
    repo=Depends(get_repo),
):
    # 하나 더 가져와서 "뒤에 더 있는지"를 봅니다. (services/paging.py)
    rows, total = repo.list_spots(
        q=q, theme=theme, area=area, category=category, indoor=indoor, after_id=cursor, size=size + 1
    )
    items, next_cursor = cut_page(rows, size, lambda spot: spot["id"])
    return {"items": with_photo_addresses(items, request), "next_cursor": next_cursor, "total": total, "size": size}


@router.get("/spots/{spot_id}", response_model=Spot)
def get_spot(spot_id: int, request: Request, repo=Depends(get_repo)):
    spot = repo.get_spot(spot_id)
    if spot is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    return with_photo_address(spot, request)


@router.get("/spots/{spot_id}/restaurants", response_model=list[NearbySpot])
def nearby_restaurants(spot_id: int, request: Request, size: int = Query(default=5, ge=1, le=10), repo=Depends(get_repo)):
    """이 곳에서 가까운 추천 식당. 직선 거리가 가까운 순으로 size 곳을 돌려줍니다."""
    spot = repo.get_spot(spot_id)
    if spot is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    found = nearest(spot, repo.list_by_categories(FOOD_CATEGORIES), size)
    return with_photo_addresses(found, request)


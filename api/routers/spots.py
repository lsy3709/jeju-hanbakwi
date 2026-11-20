"""관광지 주소: 선택지, 목록(쪽 나눔), 상세. 누구나 볼 수 있습니다."""

from fastapi import APIRouter, Depends, HTTPException, Query

from constants import AREAS, CATEGORIES, THEMES
from repo import get_repo
from schemas import Meta, Spot, SpotList

router = APIRouter(tags=["관광지"])


@router.get("/meta", response_model=Meta)
def meta():
    return {"themes": THEMES, "areas": AREAS, "categories": CATEGORIES}


@router.get("/spots", response_model=SpotList)
def list_spots(
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=50),
    repo=Depends(get_repo),
):
    items, total = repo.list_spots(page=page, size=size)
    return {"items": items, "total": total, "page": page, "size": size}


@router.get("/spots/{spot_id}", response_model=Spot)
def get_spot(spot_id: int, repo=Depends(get_repo)):
    spot = repo.get_spot(spot_id)
    if spot is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    return spot

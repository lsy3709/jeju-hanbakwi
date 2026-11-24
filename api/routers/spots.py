"""관광지 주소: 선택지, 목록(검색·필터·커서 페이징), 상세. 누구나 볼 수 있습니다."""

# 층: 이 파일(주소) → repo.py(DB). 로그인 없이 쓰는 읽기 전용 주소라 Depends 는 DB(get_repo)만 받습니다.
# 낱말: 쿼리 = 주소 뒤 ?q=바다&size=20 처럼 붙는 값. Query(...) 로 길이·범위 제한을 걸고, 어기면 422 가 됩니다.
# 낱말: {spot_id} 처럼 주소에 중괄호로 쓴 부분은 함수의 같은 이름 인자로 들어옵니다.
from fastapi import APIRouter, Depends, HTTPException, Query, Request

from constants import AREAS, CATEGORIES, THEMES
from repo import get_repo
from schemas import Meta, Spot, SpotList
from services.paging import cut_page
from services.photos import with_photo_address, with_photo_addresses

router = APIRouter(tags=["관광지"])


# 화면의 필터 단추를 만들 선택지(테마·지역·분류). 목록은 constants.py 에 있습니다.
@router.get("/meta", response_model=Meta)
def meta():
    return {"themes": THEMES, "areas": AREAS, "categories": CATEGORIES}


# 목록. q·theme·area 같은 조건은 안 보내면(None) 걸지 않습니다. cursor 는 앞 응답의 next_cursor 입니다.
# request 는 사진 주소를 "이 서버 주소 + 사진 경로"로 완성할 때(with_photo_addresses) 서버 주소를 알기 위해 받습니다.
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


# 상세. 없거나 숨긴 곳이면 404.
@router.get("/spots/{spot_id}", response_model=Spot)
def get_spot(spot_id: int, request: Request, repo=Depends(get_repo)):
    spot = repo.get_spot(spot_id)
    if spot is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    return with_photo_address(spot, request)

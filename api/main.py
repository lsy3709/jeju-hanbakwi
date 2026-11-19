"""서버의 시작점.

실행:  uvicorn main:app --reload        (api 폴더에서)
확인:  http://localhost:8000/docs       (주소를 직접 눌러 볼 수 있는 화면)
"""

from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Query, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from auth import get_current_user
from config import settings
from constants import AREAS, CATEGORIES, THEMES
from repo import get_repo
from schemas import FavoriteIn, Meta, PlanRequest, PlanResponse, Spot, SpotList, Trip, TripIn, User, Weather
from services import planner, weather

app = FastAPI(title="제주 한 바퀴 API", version="1.0.0")

# 다른 주소의 화면(웹·앱)이 이 서버를 부를 수 있게 허락합니다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    # 개발 중에는 localhost 의 어떤 포트든 허용 (Flutter 웹은 실행할 때마다 포트가 바뀝니다)
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)


# 샘플 사진은 우리 서버가 직접 내줍니다. (api/static/photos/S001.jpg → /photos/S001.jpg)
app.mount("/photos", StaticFiles(directory=Path(__file__).parent / "static" / "photos"), name="photos")


def with_photo_address(spot: dict, request: Request) -> dict:
    """DB 의 "/photos/S001.jpg" 같은 짧은 주소 앞에 이 서버의 주소를 붙입니다.

    웹은 localhost:8000, 에뮬레이터는 10.0.2.2:8000 으로 이 서버를 부릅니다.
    요청이 들어온 주소를 그대로 붙여 주면 각자 자기가 닿을 수 있는 주소로 사진을 받습니다.
    바깥 사진(https://...)이나 사진이 없는 경우는 그대로 둡니다.
    """
    image_url = spot.get("image_url")
    if not image_url or not image_url.startswith("/"):
        return spot
    base = settings.public_api_url or str(request.base_url).rstrip("/")
    return {**spot, "image_url": base + image_url}  # 원본은 건드리지 않고 복사본을 돌려줍니다


def get_weather_service():
    """날씨를 가져오는 함수. 테스트에서 가짜로 바꿔 끼울 수 있게 따로 둡니다."""
    return weather.get_weather


# ------------------------------------------------------------------ 누구나

@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/meta", response_model=Meta)
def meta():
    return {"themes": THEMES, "areas": AREAS, "categories": CATEGORIES}


@app.get("/spots", response_model=SpotList)
def list_spots(
    request: Request,
    q: str | None = Query(default=None, max_length=50),
    theme: str | None = None,
    area: str | None = None,
    category: str | None = None,
    indoor: bool | None = None,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=50),
    repo=Depends(get_repo),
):
    items, total = repo.list_spots(q=q, theme=theme, area=area, category=category, indoor=indoor, page=page, size=size)
    items = [with_photo_address(spot, request) for spot in items]
    return {"items": items, "total": total, "page": page, "size": size}


@app.get("/spots/{spot_id}", response_model=Spot)
def get_spot(spot_id: int, request: Request, repo=Depends(get_repo)):
    spot = repo.get_spot(spot_id)
    if spot is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    return with_photo_address(spot, request)


@app.get("/weather", response_model=Weather)
def get_weather(get_weather_fn=Depends(get_weather_service)):
    try:
        return get_weather_fn()
    except weather.WeatherUnavailable:
        raise HTTPException(status_code=503, detail="날씨 정보를 잠시 가져올 수 없습니다.")


@app.post("/agent/plan", response_model=PlanResponse)
def plan(body: PlanRequest, request: Request, repo=Depends(get_repo), get_weather_fn=Depends(get_weather_service)):
    result = planner.plan_trip(body, repo, get_weather_fn)
    result["sources"] = [with_photo_address(spot, request) for spot in result["sources"]]
    return result


# ------------------------------------------------------------------ 로그인한 사람만
# get_current_user 가 토큰을 확인해 준 user.id 만 씁니다. 화면이 보낸 사용자 ID 는 받지 않습니다.

@app.get("/me", response_model=User)
def me(user: User = Depends(get_current_user)):
    return user


@app.get("/me/favorites", response_model=list[Spot])
def list_favorites(request: Request, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    return [with_photo_address(spot, request) for spot in repo.list_favorites(user.id)]


@app.post("/me/favorites", status_code=201)
def add_favorite(body: FavoriteIn, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    if repo.get_spot(body.spot_id) is None:
        raise HTTPException(status_code=404, detail="관광지를 찾을 수 없습니다.")
    repo.add_favorite(user.id, body.spot_id)
    return {"spot_id": body.spot_id}


@app.delete("/me/favorites/{spot_id}", status_code=204)
def remove_favorite(spot_id: int, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    repo.remove_favorite(user.id, spot_id)
    return Response(status_code=204)


@app.get("/me/trips", response_model=list[Trip])
def list_trips(user: User = Depends(get_current_user), repo=Depends(get_repo)):
    return repo.list_trips(user.id)


@app.post("/me/trips", response_model=Trip, status_code=201)
def add_trip(body: TripIn, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    # mode="json": 날짜 같은 값을 DB 에 넣을 수 있는 글자로 바꿉니다.
    itinerary = [day.model_dump(mode="json") for day in body.itinerary]
    return repo.add_trip(user.id, body.title, itinerary)


@app.delete("/me/trips/{trip_id}", status_code=204)
def delete_trip(trip_id: int, user: User = Depends(get_current_user), repo=Depends(get_repo)):
    if not repo.delete_trip(user.id, trip_id):
        raise HTTPException(status_code=404, detail="저장한 일정을 찾을 수 없습니다.")
    return Response(status_code=204)

"""주고받는 자료의 모양. docs/api.md 와 같아야 합니다."""

import datetime as dt  # 필드 이름 date 와 겹치지 않게 dt 로 부릅니다
from typing import Literal

from pydantic import BaseModel, Field


class Spot(BaseModel):
    id: int
    title: str
    category: str
    area: str
    address: str = ""
    lat: float | None = None
    lng: float | None = None
    image_url: str | None = None
    image_credit: str | None = None       # 사진 출처 표시 (저작자 · 라이선스)
    image_source_url: str | None = None   # 사진 원본 설명 쪽 주소
    overview: str = ""
    one_liner: str = ""
    theme_tags: list[str] = []
    indoor: bool = False


class SpotList(BaseModel):
    """관광지 한 묶음. next_cursor 를 다음 요청의 cursor 로 보내면 이어지는 묶음을 받습니다."""
    items: list[Spot]
    next_cursor: int | None = None   # None 이면 끝
    total: int | None = None         # 조건에 맞는 전체 개수. 첫 묶음에서만 셉니다
    size: int


class Meta(BaseModel):
    themes: list[str]
    areas: list[str]
    categories: list[str]


class WeatherDay(BaseModel):
    date: dt.date
    label: str
    icon: Literal["sun", "cloud", "rain", "snow", "fog"]
    temp_min: float | None = None
    temp_max: float | None = None
    rain_prob: int | None = None


class WeatherArea(BaseModel):
    area: str
    days: list[WeatherDay]


class Weather(BaseModel):
    rainy_today: bool
    message: str
    areas: list[WeatherArea]


class PlanRequest(BaseModel):
    message: str = Field(min_length=1, max_length=500)
    days: int = Field(default=2, ge=1, le=3)
    companions: str | None = Field(default=None, max_length=20)
    start_date: dt.date | None = None


class PlanItem(BaseModel):
    time: Literal["오전", "점심", "오후", "저녁"]
    spot_id: int
    title: str
    reason: str = ""


class PlanDay(BaseModel):
    day: int
    date: dt.date | None = None
    weather: str | None = None
    items: list[PlanItem]


class PlanResponse(BaseModel):
    mode: Literal["ai", "rule"]
    answer: str
    itinerary: list[PlanDay]
    sources: list[Spot]


class User(BaseModel):
    id: str
    email: str | None = None


class Me(User):
    """GET /me 응답. 화면이 관리자 메뉴와 이용 정지 안내를 보여 줄지 정하는 데 씁니다."""
    is_admin: bool = False
    suspended: bool = False


class FavoriteIn(BaseModel):
    spot_id: int


class TripIn(BaseModel):
    title: str = Field(min_length=1, max_length=60)
    itinerary: list[PlanDay] = Field(min_length=1, max_length=3)


class Trip(BaseModel):
    id: int
    title: str
    itinerary: list[PlanDay]
    created_at: str


class FavoritePage(BaseModel):
    items: list[Spot]
    next_cursor: int | None = None


class TripPage(BaseModel):
    items: list[Trip]
    next_cursor: int | None = None


# ---------------------------------------------------------------- 관리자

class AdminUser(BaseModel):
    id: str
    email: str | None = None
    suspended: bool
    created_at: str
    favorite_count: int
    trip_count: int


class AdminUserPage(BaseModel):
    items: list[AdminUser]
    next_cursor: int | None = None


class AdminUserPatch(BaseModel):
    suspended: bool


class AdminSpot(Spot):
    hidden: bool = False
    source: str = ""


class AdminSpotPage(BaseModel):
    items: list[AdminSpot]
    next_cursor: int | None = None
    total: int | None = None


class SpotCreate(BaseModel):
    title: str = Field(min_length=1, max_length=60)
    category: str
    area: str
    address: str = Field(default="", max_length=120)
    one_liner: str = Field(default="", max_length=120)
    overview: str = Field(default="", max_length=2000)
    theme_tags: list[str] = Field(default=[], max_length=5)
    indoor: bool = False
    lat: float | None = Field(default=None, ge=32.5, le=34.5)    # 제주 근처만
    lng: float | None = Field(default=None, ge=125.5, le=127.5)
    image_url: str | None = Field(default=None, max_length=300, pattern=r"^https://")


class SpotPatch(BaseModel):
    """보낸 칸만 고칩니다. 숨김(hidden)도 여기로 바꿉니다."""
    title: str | None = Field(default=None, min_length=1, max_length=60)
    category: str | None = None
    area: str | None = None
    address: str | None = Field(default=None, max_length=120)
    one_liner: str | None = Field(default=None, max_length=120)
    overview: str | None = Field(default=None, max_length=2000)
    theme_tags: list[str] | None = Field(default=None, max_length=5)
    indoor: bool | None = None
    hidden: bool | None = None


class Status(BaseModel):
    """운영 확인용 응답. 키 값은 담지 않고 "있다/없다"만 담습니다."""

    database: Literal["ok", "error"]
    spots: int | None = None
    ai: Literal["ai", "rule"]
    login: Literal["on", "off"]
    photos: int

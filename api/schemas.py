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


class NearbySpot(Spot):
    """가까운 곳 한 건. 기준이 된 곳에서의 직선 거리가 붙습니다."""
    distance_km: float


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
    place_categories: list[str] = []  # 편의 시설 분류(숙소 · 병원 · 약국 …). 골랐을 때만 목록에 나옵니다
    food_categories: list[str] = []   # 추천 식당 분류(한식 · 해산물 …). 골랐을 때만 목록에 나옵니다


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


class SavedTrip(BaseModel):
    """자동 저장된 일정을 가리키는 값."""

    id: int
    title: str


class PlanResponse(BaseModel):
    mode: Literal["ai", "rule"]
    answer: str
    itinerary: list[PlanDay]
    sources: list[Spot]
    # 사용자가 보낸 자기 AI 키로 일정을 받지 못해 다른 방식으로 대신했을 때만 안내 글이 옵니다.
    notice: str | None = None
    # 로그인한 채로 불렀으면 "내 여행"에 자동 저장하고 그 일정의 번호와 제목을 돌려줍니다. 아니면 None.
    saved_trip: SavedTrip | None = None


class KeyCheck(BaseModel):
    """POST /agent/key-check 응답. 키 값은 담지 않습니다."""

    ok: bool
    message: str


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


# 사진 주소: 바깥 사진(https://...) 이거나, 이 서버의 사진 폴더 안 파일(/photos/S001.jpg)만 받습니다.
# 폴더 이름 칸에 점(.)을 못 쓰게 해서 /photos/../ 처럼 폴더 밖으로 나가는 주소를 막습니다.
PHOTO_URL = r"^(https://\S+|/photos/[\w-]+(/[\w-]+)*\.(jpg|jpeg|png|webp))$"


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
    image_url: str | None = Field(default=None, max_length=300, pattern=PHOTO_URL)
    image_credit: str | None = Field(default=None, max_length=200)     # 저작자 · 라이선스
    image_source_url: str | None = Field(default=None, max_length=300, pattern=r"^https://")


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
    # 사진도 바꿀 수 있습니다. 여러 곳이 같은 사진을 쓰고 있을 때 한 곳씩 다른 사진으로 고치는 용도입니다.
    image_url: str | None = Field(default=None, max_length=300, pattern=PHOTO_URL)
    # 출처 두 칸은 빈 글자("")로 보내면 지워집니다. 사진을 바꿀 때 옛 사진의 출처가 남지 않게 하려는 것입니다.
    image_credit: str | None = Field(default=None, max_length=200)
    image_source_url: str | None = Field(default=None, max_length=300, pattern=r"^(https://\S+)?$")


class UsageSummary(BaseModel):
    """AI 사용량을 더한 값. server_tokens_total 은 서버 키로 쓴 토큰(서비스가 내는 몫)입니다."""

    requests: int
    ai_requests: int
    rule_requests: int
    user_key_requests: int
    server_key_requests: int
    tokens_in: int
    tokens_out: int
    tokens_total: int
    server_tokens_total: int


class UsageDay(UsageSummary):
    date: str


class UsageUser(UsageSummary):
    user_id: str | None = None   # 로그인하지 않은 요청은 None 한 줄로 묶임
    email: str | None = None


class UsageReport(BaseModel):
    days: int
    total: UsageSummary
    today: UsageSummary
    by_day: list[UsageDay]
    by_user: list[UsageUser] | None = None   # 관리자 주소에만 있음
    truncated: bool = False


class Status(BaseModel):
    """운영 확인용 응답. 키 값은 담지 않고 "있다/없다"만 담습니다."""

    database: Literal["ok", "error"]
    spots: int | None = None
    ai: Literal["ai", "rule"]
    login: Literal["on", "off"]
    photos: int

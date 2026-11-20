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
    items: list[Spot]
    total: int
    page: int
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


class User(BaseModel):
    id: str
    email: str | None = None


class FavoriteIn(BaseModel):
    spot_id: int


class Status(BaseModel):
    """운영 확인용 응답. 키 값은 담지 않고 "있다/없다"만 담습니다."""

    database: Literal["ok", "error"]
    spots: int | None = None
    login: Literal["on", "off"]
    photos: int

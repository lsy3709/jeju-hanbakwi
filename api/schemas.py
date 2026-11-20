"""주고받는 자료의 모양. docs/api.md 와 같아야 합니다."""

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

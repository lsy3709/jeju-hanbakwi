"""날씨 주소. 누구나 볼 수 있습니다."""

from fastapi import APIRouter, Depends, HTTPException

from deps import get_weather_service
from schemas import Weather
from services.weather import WeatherUnavailable

router = APIRouter(tags=["날씨"])


@router.get("/weather", response_model=Weather)
def get_weather(get_weather_fn=Depends(get_weather_service)):
    try:
        return get_weather_fn()
    except WeatherUnavailable:
        raise HTTPException(status_code=503, detail="날씨 정보를 잠시 가져올 수 없습니다.")

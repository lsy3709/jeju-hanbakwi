"""날씨 주소. 누구나 볼 수 있습니다."""

# 층: 이 파일(주소) → deps.get_weather_service 가 내주는 날씨 함수 → services/weather.py → 바깥 날씨 서비스.
# 날씨 함수를 Depends 로 받으므로 테스트에서는 진짜 날씨 서비스를 부르지 않고 가짜 함수로 바꿔 끼웁니다.
from fastapi import APIRouter, Depends, HTTPException

from deps import get_weather_service
from schemas import Weather
from services.weather import WeatherUnavailable

router = APIRouter(tags=["날씨"])


@router.get("/weather", response_model=Weather)
def get_weather(get_weather_fn=Depends(get_weather_service)):
    try:
        return get_weather_fn()
    # 날씨 서비스가 실패하면 503(잠시 이용 불가)으로 알립니다. 서버 잘못(500)과 구분하려는 것입니다.
    except WeatherUnavailable:
        raise HTTPException(status_code=503, detail="날씨 정보를 잠시 가져올 수 없습니다.")

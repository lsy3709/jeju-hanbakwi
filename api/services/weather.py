"""날씨: Open-Meteo(무료, 키 없음)에서 받아 우리 화면에 맞는 모양으로 바꿉니다."""

import time

import httpx

# 날씨를 볼 두 곳 (위도, 경도)
PLACES = {"제주시": (33.4996, 126.5312), "서귀포시": (33.2541, 126.5600)}

URL = "https://api.open-meteo.com/v1/forecast"
CACHE_SECONDS = 600  # 10분 동안은 다시 묻지 않습니다 (속도 + 상대 서버 배려)
_cache: dict = {"at": 0.0, "value": None}


class WeatherUnavailable(Exception):
    """날씨 서비스가 응답하지 않을 때."""


def describe(code: int) -> tuple[str, str]:
    """날씨 번호(WMO 코드) → (한글 이름, 아이콘 이름)"""
    if code == 0:
        return "맑음", "sun"
    if code == 1:
        return "대체로 맑음", "sun"
    if code == 2:
        return "구름 조금", "cloud"
    if code == 3:
        return "흐림", "cloud"
    if code in (45, 48):
        return "안개", "fog"
    if 51 <= code <= 57:
        return "이슬비", "rain"
    if 61 <= code <= 67:
        return "비", "rain"
    if 71 <= code <= 77 or code in (85, 86):
        return "눈", "snow"
    if 80 <= code <= 82:
        return "소나기", "rain"
    if code >= 95:
        return "뇌우", "rain"
    return "흐림", "cloud"


def parse_days(data: dict) -> list[dict]:
    """Open-Meteo 응답(날짜별 배열 여러 개) → 날짜 하나에 값이 모인 목록"""
    daily = data["daily"]
    days = []
    for i, day in enumerate(daily["time"]):
        label, icon = describe(int(daily["weather_code"][i]))
        rain = daily.get("precipitation_probability_max", [None] * len(daily["time"]))[i]
        days.append(
            {
                "date": day,
                "label": label,
                "icon": icon,
                "temp_min": daily["temperature_2m_min"][i],
                "temp_max": daily["temperature_2m_max"][i],
                "rain_prob": int(rain) if rain is not None else None,
            }
        )
    return days


def is_rainy(day: dict) -> bool:
    """비·눈이 오거나 강수 확률이 60% 이상이면 "실내가 좋은 날"로 봅니다."""
    return day["icon"] in ("rain", "snow") or (day.get("rain_prob") or 0) >= 60


def build_weather(areas: list[dict]) -> dict:
    today = [area["days"][0] for area in areas if area["days"]]
    rainy = any(is_rainy(day) for day in today)
    if rainy:
        message = "오늘 제주는 비 소식이 있어요. 실내 코스를 추천해요."
    else:
        label = today[0]["label"] if today else "알 수 없음"
        message = f"오늘 제주는 {label}. 바깥 나들이 하기 좋아요."
    return {"rainy_today": rainy, "message": message, "areas": areas}


def get_weather() -> dict:
    """제주시·서귀포시 오늘부터 4일 날씨."""
    if _cache["value"] and time.time() - _cache["at"] < CACHE_SECONDS:
        return _cache["value"]
    areas = []
    try:
        for name, (lat, lng) in PLACES.items():
            response = httpx.get(
                URL,
                params={
                    "latitude": lat,
                    "longitude": lng,
                    "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max",
                    "timezone": "Asia/Seoul",
                    "forecast_days": 4,
                },
                timeout=8,
            )
            response.raise_for_status()
            areas.append({"area": name, "days": parse_days(response.json())})
    except (httpx.HTTPError, KeyError, ValueError) as error:
        raise WeatherUnavailable(str(error)) from error
    value = build_weather(areas)
    _cache.update(at=time.time(), value=value)
    return value

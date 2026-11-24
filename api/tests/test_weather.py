"""날씨 응답을 우리 모양으로 바꾸는 부분. (진짜 날씨 서버는 부르지 않습니다)"""

# OPEN_METEO 는 날씨 서비스가 주는 응답을 흉내 낸 값입니다(항목별 배열 모양). 네트워크 없이 변환 함수만 확인합니다.
from services.weather import build_weather, describe, is_rainy, parse_days

OPEN_METEO = {
    "daily": {
        "time": ["2026-12-01", "2026-12-02"],
        "weather_code": [63, 1],
        "temperature_2m_max": [12.4, 14.0],
        "temperature_2m_min": [8.1, 7.5],
        "precipitation_probability_max": [80, 10],
    }
}


def test_weather_codes():
    assert describe(0) == ("맑음", "sun")
    assert describe(3) == ("흐림", "cloud")
    assert describe(45)[1] == "fog"
    assert describe(63) == ("비", "rain")
    assert describe(73)[1] == "snow"
    assert describe(81) == ("소나기", "rain")
    assert describe(96)[1] == "rain"


def test_parse_days():
    days = parse_days(OPEN_METEO)
    assert days[0] == {"date": "2026-12-01", "label": "비", "icon": "rain", "temp_min": 8.1, "temp_max": 12.4, "rain_prob": 80}
    assert days[1]["icon"] == "sun"


def test_parse_days_without_rain_probability():
    data = {"daily": {k: v for k, v in OPEN_METEO["daily"].items() if k != "precipitation_probability_max"}}
    assert parse_days(data)[0]["rain_prob"] is None


def test_rainy_rule():
    assert is_rainy({"icon": "rain", "rain_prob": 20})
    assert is_rainy({"icon": "cloud", "rain_prob": 60})
    assert not is_rainy({"icon": "cloud", "rain_prob": 59})
    assert not is_rainy({"icon": "sun", "rain_prob": None})


def test_message_changes_with_rain():
    days = parse_days(OPEN_METEO)
    rainy = build_weather([{"area": "제주시", "days": days}])
    assert rainy["rainy_today"] is True
    assert "실내" in rainy["message"]

    clear = build_weather([{"area": "제주시", "days": days[1:]}])
    assert clear["rainy_today"] is False
    assert "대체로 맑음" in clear["message"]

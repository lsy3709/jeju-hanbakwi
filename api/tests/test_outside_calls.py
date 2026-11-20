"""바깥 서비스를 부르는 곳(날씨). 진짜로 부르지 않고 가짜 연결로 바꿔 끼웁니다.

"연결을 한 번 만들어 계속 쓴다"(_http)가 핵심입니다.
요청마다 새로 만들면 그때마다 0.2초쯤 더 걸립니다.
"""

import httpx
import pytest

from services import weather


class FakeResponse:
    def __init__(self, status=200, data=None):
        self.status_code = status
        self._data = data or {}

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPError("bad status")

    def json(self):
        return self._data


class FakeHttp:
    """httpx.Client 흉내. 무엇을 몇 번 불렀는지 적어 둡니다."""

    def __init__(self, response=None, error=None):
        self.response, self.error, self.calls = response, error, []

    def get(self, url, **kwargs):
        self.calls.append((url, kwargs))
        if self.error:
            raise self.error
        return self.response


# ---------------------------------------------------------------- 날씨

OPEN_METEO = {
    "daily": {
        "time": ["2026-12-01", "2026-12-02", "2026-12-03", "2026-12-04"],
        "weather_code": [63, 1, 2, 3],
        "temperature_2m_max": [12.4, 14.0, 13.0, 11.0],
        "temperature_2m_min": [8.1, 7.5, 7.0, 6.0],
        "precipitation_probability_max": [80, 10, 20, 30],
    }
}


def use_weather(monkeypatch, fake):
    monkeypatch.setattr(weather, "_http", fake)
    monkeypatch.setattr(weather, "_cache", {"at": 0.0, "value": None})  # 캐시를 비우고 시작


def test_weather_asks_once_per_area_then_uses_cache(monkeypatch):
    fake = FakeHttp(FakeResponse(200, OPEN_METEO))
    use_weather(monkeypatch, fake)

    result = weather.get_weather()
    assert [a["area"] for a in result["areas"]] == ["제주시", "서귀포시"]
    assert result["rainy_today"] is True
    assert len(fake.calls) == 2

    weather.get_weather()  # 10분 안에는 다시 묻지 않습니다
    assert len(fake.calls) == 2


def test_weather_failure_is_reported(monkeypatch):
    use_weather(monkeypatch, FakeHttp(FakeResponse(500)))
    with pytest.raises(weather.WeatherUnavailable):
        weather.get_weather()


def test_weather_network_error_is_reported(monkeypatch):
    use_weather(monkeypatch, FakeHttp(error=httpx.ConnectTimeout("slow")))
    with pytest.raises(weather.WeatherUnavailable):
        weather.get_weather()

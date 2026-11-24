"""바깥 서비스를 부르는 곳(로그인 확인, 날씨). 진짜로 부르지 않고 가짜 연결로 바꿔 끼웁니다.

두 곳 모두 "연결을 한 번 만들어 계속 쓴다"(_http)가 핵심입니다.
요청마다 새로 만들면 그때마다 0.2초쯤 더 걸립니다.
"""

# 방법: 진짜 연결(auth._http, weather._http) 자리에 FakeHttp 를 끼워, 바깥 서버에 가지 않고 "어떤 응답이 오면 우리 코드가 어떻게 반응하는지"를 봅니다.
# monkeypatch.setattr 는 테스트 동안만 값을 바꿨다가 끝나면 되돌려 줍니다.
import httpx
import pytest

import auth
from config import settings
from services import weather


# 바깥 서버의 답을 흉내 냅니다. status 가 400 이상이면 raise_for_status() 가 오류를 내는 점까지 진짜와 같게 만들었습니다.
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


# ---------------------------------------------------------------- 로그인 확인

def use_auth(monkeypatch, fake):
    monkeypatch.setattr(settings, "supabase_url", "https://example.supabase.co")
    monkeypatch.setattr(settings, "supabase_service_role_key", "secret")
    monkeypatch.setattr(auth, "_http", fake)


def test_valid_token_gives_user(monkeypatch):
    fake = FakeHttp(FakeResponse(200, {"id": "user-1", "email": "a@example.com"}))
    use_auth(monkeypatch, fake)
    user = auth.verify_token("good-token")
    assert user.id == "user-1" and user.email == "a@example.com"
    url, kwargs = fake.calls[0]
    assert url == "https://example.supabase.co/auth/v1/user"
    assert kwargs["headers"]["Authorization"] == "Bearer good-token"


def test_rejected_token_gives_none(monkeypatch):
    use_auth(monkeypatch, FakeHttp(FakeResponse(401, {"msg": "invalid"})))
    assert auth.verify_token("bad") is None


def test_response_without_id_gives_none(monkeypatch):
    use_auth(monkeypatch, FakeHttp(FakeResponse(200, {})))
    assert auth.verify_token("odd") is None


def test_network_error_gives_none(monkeypatch):
    use_auth(monkeypatch, FakeHttp(error=httpx.ConnectError("down")))
    assert auth.verify_token("any") is None


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


# 두 지역을 한 번씩만 부르고, 두 번째 요청부터는 캐시(기억해 둔 답)를 쓰는지 확인합니다.
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

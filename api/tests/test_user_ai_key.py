"""사용자가 넣은 자기 AI 키(X-Gemini-Key)로 일정 짜기. AI 는 가짜를 씁니다."""

import logging

import pytest

import main
from config import settings
from deps import get_ai_asker, get_key_checker
from schemas import PlanRequest
from services import planner
from tests.fakes import FakeRepo, make_weather

USER_KEY = "AIzaUserKey_1234567890-abcdefghij"   # 형식만 맞는 가짜 키
GOOD_ANSWER = '{"answer": "동쪽 코스입니다.", "itinerary": [{"day": 1, "items": [{"time": "오전", "spot_id": 1, "reason": "일출"}]}]}'


def request(**kw):
    return PlanRequest(**{"message": "바다 보고 싶어요", "days": 1, **kw})


class FakeAi:
    """AI 에게 묻는 함수의 가짜. 어떤 키로 불렸는지 적어 두고, fail_keys 에 든 키로 부르면 실패합니다."""

    def __init__(self, fail_keys=()):
        self.keys = []
        self.fail_keys = set(fail_keys)

    def __call__(self, req, repo, get_weather, found, api_key=None):
        self.keys.append(api_key)
        if api_key in self.fail_keys:
            raise RuntimeError(f"API key not valid: {api_key}")   # 오류 글에 키가 섞여 오는 최악의 경우
        found[1] = repo.get_spot(1)
        return GOOD_ANSWER


# ---------------------------------------------------------------- 일정 짜기 (services/planner.py)

def test_user_key_is_used_even_without_server_key():
    ai = FakeAi()
    plan = planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=ai, user_key=USER_KEY)
    assert plan["mode"] == "ai"
    assert plan["notice"] is None
    assert ai.keys == [USER_KEY]


def test_without_user_key_old_style_ask_function_still_works(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "server-key")
    repo = FakeRepo()

    def old_style(req, repo_, get_weather, found):   # api_key 인자가 없는 예전 모양
        found[1] = repo.get_spot(1)
        return GOOD_ANSWER

    plan = planner.plan_trip(request(), repo, make_weather(False), ask_ai=old_style)
    assert plan["mode"] == "ai"
    assert plan["notice"] is None


def test_bad_user_key_falls_back_to_rule_with_notice(caplog):
    ai = FakeAi(fail_keys=[USER_KEY])
    with caplog.at_level(logging.WARNING):
        plan = planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=ai, user_key=USER_KEY)
    assert plan["mode"] == "rule"
    assert "설정" in plan["notice"]
    assert plan["itinerary"][0]["items"]
    # 키는 로그에도, 응답에도 남지 않습니다.
    assert USER_KEY not in caplog.text
    assert USER_KEY not in str(plan)


def test_bad_user_key_falls_back_to_server_key_first(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "server-key")
    ai = FakeAi(fail_keys=[USER_KEY])
    plan = planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=ai, user_key=USER_KEY)
    assert plan["mode"] == "ai"
    assert plan["notice"]
    assert ai.keys == [USER_KEY, None]   # 내 키로 먼저, 안 되면 서버 키(None = 서버 설정 값)로


def test_no_key_at_all_is_rule_without_notice():
    ai = FakeAi()
    plan = planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=ai)
    assert plan["mode"] == "rule"
    assert plan["notice"] is None
    assert ai.keys == []


# ---------------------------------------------------------------- 주소 (routers/agent.py)

@pytest.fixture
def ai(client):
    fake = FakeAi()
    main.app.dependency_overrides[get_ai_asker] = lambda: fake
    yield fake
    main.app.dependency_overrides.pop(get_ai_asker, None)


BODY = {"message": "바다 보고 싶어요", "days": 1}


def test_plan_route_passes_header_key_to_ai(client, ai):
    response = client.post("/agent/plan", json=BODY, headers={"X-Gemini-Key": USER_KEY})
    assert response.status_code == 200
    assert response.json()["mode"] == "ai"
    assert response.json()["notice"] is None
    assert ai.keys == [USER_KEY]
    assert USER_KEY not in response.text


def test_plan_route_accepts_new_style_key_with_dots(client, ai):
    dotted = "AQ.fake-key-for-tests_0000000000.abcdefghijklmnopqrst"   # 마침표가 든 새 형식의 키(가짜)
    response = client.post("/agent/plan", json=BODY, headers={"X-Gemini-Key": dotted})
    assert response.status_code == 200
    assert ai.keys == [dotted]


def test_plan_route_without_header_is_as_before(client, ai):
    response = client.post("/agent/plan", json=BODY)
    assert response.status_code == 200
    assert response.json()["mode"] == "rule"
    assert response.json()["notice"] is None
    assert ai.keys == []


@pytest.mark.parametrize("bad", ["짧음", "short", "has space in the key 1234567890", "x" * 201, "abc<script>1234567890abcdef"])
def test_plan_route_rejects_malformed_key(client, ai, bad):
    response = client.post("/agent/plan", content=b'{"message": "a", "days": 1}', headers={"X-Gemini-Key": bad.encode("utf-8"), "Content-Type": "application/json"})
    assert response.status_code == 422
    assert ai.keys == []


def test_key_check_route(client):
    seen = []

    def checker(key):
        seen.append(key)
        return key == USER_KEY

    main.app.dependency_overrides[get_key_checker] = lambda: checker
    try:
        good = client.post("/agent/key-check", headers={"X-Gemini-Key": USER_KEY})
        bad = client.post("/agent/key-check", headers={"X-Gemini-Key": "AIzaWrongKey_1234567890-abcdefghi"})
        missing = client.post("/agent/key-check")
    finally:
        main.app.dependency_overrides.pop(get_key_checker, None)

    assert good.status_code == 200 and good.json()["ok"] is True
    assert bad.status_code == 200 and bad.json()["ok"] is False and bad.json()["message"]
    assert missing.status_code == 422
    assert len(seen) == 2
    assert USER_KEY not in good.text


def test_key_check_reports_failure_when_checker_breaks(client):
    def broken(key):
        raise RuntimeError(f"network down {key}")

    main.app.dependency_overrides[get_key_checker] = lambda: broken
    try:
        response = client.post("/agent/key-check", headers={"X-Gemini-Key": USER_KEY})
    finally:
        main.app.dependency_overrides.pop(get_key_checker, None)
    assert response.status_code == 200
    assert response.json()["ok"] is False
    assert USER_KEY not in response.text

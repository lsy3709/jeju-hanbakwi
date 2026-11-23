"""AI 사용량: 일정을 짤 때마다 한 줄 적고, 본인과 관리자가 모아 봅니다."""

from datetime import datetime, timezone

import pytest

import main
from auth import get_optional_user
from config import settings
from deps import get_ai_asker
from schemas import PlanRequest
from services import planner, usage
from tests.conftest import ADMIN, ALICE, BOB
from tests.fakes import FakeRepo, make_weather

BODY = {"message": "바다 보고 싶어요", "days": 1}
USER_KEY = "AIzaUserKey_1234567890-abcdefghij"
GOOD_ANSWER = '{"answer": "동쪽 코스입니다.", "itinerary": [{"day": 1, "items": [{"time": "오전", "spot_id": 1, "reason": "일출"}]}]}'


def row(**kw):
    base = {"user_id": ALICE.id, "mode": "ai", "key_source": "server", "days": 1, "duration_ms": 900, "ai_calls": 2,
            "tokens_in": 100, "tokens_out": 20, "tokens_total": 120, "created_at": "2026-12-01T03:00:00+00:00"}
    return {**base, **kw}


# ---------------------------------------------------------------- 모으는 계산 (services/usage.py)

def test_summarize_counts_requests_and_tokens():
    rows = [
        row(),
        row(key_source="user", tokens_in=50, tokens_out=10, tokens_total=60),
        row(mode="rule", key_source="none", ai_calls=0, tokens_in=0, tokens_out=0, tokens_total=0),
    ]
    assert usage.summarize(rows) == {
        "requests": 3, "ai_requests": 2, "rule_requests": 1, "user_key_requests": 1, "server_key_requests": 1,
        "tokens_in": 150, "tokens_out": 30, "tokens_total": 180, "server_tokens_total": 120,
    }
    assert usage.summarize([])["requests"] == 0


def test_by_day_uses_korea_date_and_newest_first():
    rows = [
        row(created_at="2026-12-01T03:00:00+00:00"),            # 한국 12월 1일 낮 12시
        row(created_at="2026-12-01T16:30:00+00:00"),            # 한국 12월 2일 새벽 1시 30분
        row(created_at="2026-12-01T14:59:59.123456+00:00"),     # 한국 12월 1일 밤 11시 59분
    ]
    days = usage.by_day(rows)
    assert [(d["date"], d["requests"]) for d in days] == [("2026-12-02", 1), ("2026-12-01", 2)]


def test_by_user_groups_anonymous_and_sorts_by_tokens():
    rows = [row(tokens_total=10), row(user_id=BOB.id, tokens_total=500), row(user_id=None, tokens_total=0, mode="rule", key_source="none"), row(user_id=None)]
    users = usage.by_user(rows, {ALICE.id: "alice@example.com", BOB.id: "bob@example.com"})
    assert [(u["email"], u["requests"]) for u in users] == [("bob@example.com", 1), (None, 2), ("alice@example.com", 1)]
    assert users[1]["user_id"] is None


def test_report_splits_today_from_the_period():
    now = datetime(2026, 12, 2, 1, 0, tzinfo=timezone.utc)   # 한국 12월 2일 오전 10시
    rows = [row(created_at="2026-12-01T16:30:00+00:00"), row(created_at="2026-11-30T03:00:00+00:00")]
    report = usage.report(rows, days=30, now=now)
    assert report["days"] == 30
    assert report["total"]["requests"] == 2
    assert report["today"]["requests"] == 1
    assert report["truncated"] is False


# ---------------------------------------------------------------- 적기 (POST /agent/plan)

class FakeAi:
    """AI 에게 묻는 함수의 가짜. (글, 사용량)을 함께 돌려줍니다."""

    def __call__(self, req, repo, get_weather, found, api_key=None):
        found[1] = repo.get_spot(1)
        return GOOD_ANSWER, {"ai_calls": 3, "tokens_in": 1200, "tokens_out": 300, "tokens_total": 1500}


@pytest.fixture
def ai(client):
    main.app.dependency_overrides[get_ai_asker] = lambda: FakeAi()
    yield
    main.app.dependency_overrides.pop(get_ai_asker, None)


def test_plan_trip_reports_usage_for_each_way(monkeypatch):
    request = PlanRequest(**BODY)
    rule = planner.plan_trip(request, FakeRepo(), make_weather(False))
    assert rule["usage"] == {"key_source": "none", "ai_calls": 0, "tokens_in": 0, "tokens_out": 0, "tokens_total": 0}

    mine = planner.plan_trip(request, FakeRepo(), make_weather(False), ask_ai=FakeAi(), user_key=USER_KEY)
    assert mine["usage"] == {"key_source": "user", "ai_calls": 3, "tokens_in": 1200, "tokens_out": 300, "tokens_total": 1500}

    monkeypatch.setattr(settings, "gemini_api_key", "server-key")
    server = planner.plan_trip(request, FakeRepo(), make_weather(False), ask_ai=FakeAi())
    assert server["usage"]["key_source"] == "server"


def test_old_style_ask_function_without_usage_counts_zero_tokens(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "server-key")
    repo = FakeRepo()

    def old_style(req, repo_, get_weather, found):   # 글만 돌려주는 예전 모양
        found[1] = repo.get_spot(1)
        return GOOD_ANSWER

    plan = planner.plan_trip(PlanRequest(**BODY), repo, make_weather(False), ask_ai=old_style)
    assert plan["mode"] == "ai"
    assert plan["usage"]["key_source"] == "server"
    assert plan["usage"]["tokens_total"] == 0


def test_failed_ai_attempt_still_counts_its_tokens(monkeypatch):
    """AI 가 도중에 실패해 규칙으로 넘어가도, 그 시도에서 쓴 토큰은 사용량에 잡힙니다."""
    monkeypatch.setattr(settings, "gemini_api_key", "server-key")

    def failing(req, repo_, get_weather, found, api_key=None):
        error = TimeoutError("AI 가 늦음")
        error.usage = {"ai_calls": 2, "tokens_in": 700, "tokens_out": 50, "tokens_total": 750}
        raise error

    plan = planner.plan_trip(PlanRequest(**BODY), FakeRepo(), make_weather(False), ask_ai=failing)
    assert plan["mode"] == "rule"
    assert plan["usage"] == {"key_source": "server", "ai_calls": 2, "tokens_in": 700, "tokens_out": 50, "tokens_total": 750}

    # 내 키로 실패하고 서버 키로 성공하면 둘을 더하고, 쓴 키는 성공한 쪽으로 적습니다.
    def user_fails(req, repo_, get_weather, found, api_key=None):
        if api_key:
            return failing(req, repo_, get_weather, found, api_key)
        return FakeAi()(req, repo_, get_weather, found)

    plan = planner.plan_trip(PlanRequest(**BODY), FakeRepo(), make_weather(False), ask_ai=user_fails, user_key=USER_KEY)
    assert plan["mode"] == "ai"
    assert plan["usage"] == {"key_source": "server", "ai_calls": 5, "tokens_in": 1900, "tokens_out": 350, "tokens_total": 2250}


def test_each_plan_request_writes_one_row(client, repo, ai):
    response = client.post("/agent/plan", json=BODY)                                   # 로그인 없이, 키 없이 → 규칙
    assert response.status_code == 200
    assert "usage" not in response.json()                                              # 응답에는 싣지 않습니다
    client.post("/agent/plan", json={**BODY, "days": 3}, headers={"X-Gemini-Key": USER_KEY})   # 내 키 → AI

    assert len(repo.ai_usage) == 2
    first, second = repo.ai_usage
    assert (first["user_id"], first["mode"], first["key_source"], first["tokens_total"]) == (None, "rule", "none", 0)
    assert (second["mode"], second["key_source"], second["days"], second["ai_calls"], second["tokens_total"]) == ("ai", "user", 3, 3, 1500)
    assert second["duration_ms"] >= 0
    # 요청 글 · 키는 적지 않습니다.
    assert "바다" not in str(repo.ai_usage) and USER_KEY not in str(repo.ai_usage)


def test_logged_in_plan_is_recorded_with_user(client, repo, ai):
    main.app.dependency_overrides[get_optional_user] = lambda: ALICE
    client.post("/agent/plan", json=BODY)
    assert repo.ai_usage[0]["user_id"] == ALICE.id


def test_recording_failure_does_not_break_the_plan(client, repo, monkeypatch):
    def broken(*args, **kwargs):
        raise RuntimeError("ai_usage 표가 없음")

    monkeypatch.setattr(repo, "add_ai_usage", broken)
    response = client.post("/agent/plan", json=BODY)
    assert response.status_code == 200
    assert response.json()["itinerary"]


# ---------------------------------------------------------------- 보기 (GET /me/ai-usage · /admin/ai-usage)

def seed(repo):
    now = datetime.now(timezone.utc).isoformat()
    repo.ai_usage += [
        row(created_at=now),
        row(created_at=now, key_source="user", tokens_total=60, tokens_in=50, tokens_out=10),
        row(created_at=now, user_id=BOB.id, tokens_total=900, tokens_in=800, tokens_out=100),
        row(created_at=now, user_id=None, mode="rule", key_source="none", ai_calls=0, tokens_in=0, tokens_out=0, tokens_total=0),
        row(created_at="2020-01-01T00:00:00+00:00"),   # 기간 밖
    ]
    repo.add_profile(ALICE.id, ALICE.email)
    repo.add_profile(BOB.id, BOB.email)


def test_my_usage_shows_only_mine(client, repo, login):
    seed(repo)
    assert client.get("/me/ai-usage").status_code == 401

    login(ALICE)
    mine = client.get("/me/ai-usage").json()
    assert mine["total"]["requests"] == 2
    assert mine["total"]["tokens_total"] == 180
    assert mine["today"]["requests"] == 2
    assert len(mine["by_day"]) == 1
    assert "by_user" not in mine or mine["by_user"] is None

    login(BOB)
    assert client.get("/me/ai-usage").json()["total"]["tokens_total"] == 900


def test_admin_usage_shows_everyone_and_is_guarded(client, repo, login):
    seed(repo)
    assert client.get("/admin/ai-usage").status_code == 401
    login(ALICE)
    assert client.get("/admin/ai-usage").status_code == 403

    login(ADMIN)
    report = client.get("/admin/ai-usage").json()
    assert report["total"]["requests"] == 4
    assert report["total"]["server_tokens_total"] == 120 + 900
    assert [(u["email"], u["requests"]) for u in report["by_user"]] == [("bob@example.com", 1), ("alice@example.com", 2), (None, 1)]


@pytest.mark.parametrize("path", ["/me/ai-usage", "/admin/ai-usage"])
def test_days_must_be_1_to_90(client, repo, login, path):
    login(ADMIN)
    assert client.get(f"{path}?days=0").status_code == 422
    assert client.get(f"{path}?days=91").status_code == 422
    assert client.get(f"{path}?days=7").json()["days"] == 7


def test_missing_table_is_503_with_a_hint(client, repo, login, monkeypatch):
    def broken(*args, **kwargs):
        raise RuntimeError("relation ai_usage does not exist")

    monkeypatch.setattr(repo, "list_ai_usage", broken)
    login(ADMIN)
    for path in ("/me/ai-usage", "/admin/ai-usage"):
        response = client.get(path)
        assert response.status_code == 503
        assert "004" in response.json()["detail"]

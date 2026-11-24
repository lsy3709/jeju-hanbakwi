"""로그인한 채로 일정을 짜면 "내 여행"에 자동 저장. (POST /agent/plan 의 saved_trip)"""

# 일정 짜기는 로그인이 "선택"입니다. 로그인했으면 자동 저장하고, 아니거나 정지·저장 실패여도 일정은 그대로 돌려줘야 합니다.
import pytest

import main
from auth import get_optional_user
from services import planner
from tests.conftest import ALICE, BOB

BODY = {"message": "바다 보고 싶어요", "days": 1}


@pytest.fixture
def login_optional():
    """login_optional(ALICE) 처럼 부르면, 로그인이 "선택"인 주소에서 그 사용자로 로그인한 것으로 칩니다."""

    def _login(user):
        main.app.dependency_overrides[get_optional_user] = lambda: user

    return _login


def test_auto_title_uses_first_30_chars_on_one_line():
    assert planner.auto_title("  바다   보고\n싶어요 ") == "바다 보고 싶어요"
    long = "가" * 45
    assert planner.auto_title(long) == "가" * 30 + "…"
    assert len(planner.auto_title(long)) <= 60


def test_plan_without_login_is_not_saved(client, repo):
    response = client.post("/agent/plan", json=BODY)
    assert response.status_code == 200
    assert response.json()["saved_trip"] is None
    assert repo.trips == []


def test_plan_with_login_is_saved_to_my_trips(client, repo, login, login_optional):
    login_optional(ALICE)
    response = client.post("/agent/plan", json=BODY)
    assert response.status_code == 200
    saved = response.json()["saved_trip"]
    assert saved["title"] == "바다 보고 싶어요"

    # 저장된 것은 내 일정 목록에 그대로 보이고, 내용은 응답의 일정과 같습니다.
    login(ALICE)
    trips = client.get("/me/trips").json()["items"]
    assert [t["id"] for t in trips] == [saved["id"]]
    assert trips[0]["itinerary"] == response.json()["itinerary"]

    # 남에게는 보이지 않습니다.
    login(BOB)
    assert client.get("/me/trips").json()["items"] == []


def test_each_plan_is_saved_separately(client, repo, login_optional):
    login_optional(ALICE)
    first = client.post("/agent/plan", json=BODY).json()["saved_trip"]
    second = client.post("/agent/plan", json={**BODY, "message": "오름 위주로"}).json()["saved_trip"]
    assert first["id"] != second["id"]
    assert [t["title"] for t in repo.trips] == ["바다 보고 싶어요", "오름 위주로"]


def test_suspended_user_gets_plan_but_nothing_is_saved(client, repo, login_optional):
    repo.profiles.append({"no": 1, "id": ALICE.id, "email": ALICE.email, "suspended": True, "created_at": "2026-12-01T00:00:00+00:00"})
    login_optional(ALICE)
    response = client.post("/agent/plan", json=BODY)
    assert response.status_code == 200
    assert response.json()["itinerary"]
    assert response.json()["saved_trip"] is None
    assert repo.trips == []


def test_save_failure_does_not_break_the_plan(client, repo, login_optional, monkeypatch):
    def broken(*args, **kwargs):
        raise RuntimeError("DB 가 응답하지 않음")

    monkeypatch.setattr(repo, "add_trip", broken)
    login_optional(ALICE)
    response = client.post("/agent/plan", json=BODY)
    assert response.status_code == 200
    assert response.json()["itinerary"]
    assert response.json()["saved_trip"] is None


def test_wrong_token_is_treated_as_not_logged_in(client, repo):
    # 진짜 문지기를 그대로 씁니다. 테스트에서는 Supabase 설정이 비어 있어 어떤 토큰도 확인되지 않습니다.
    response = client.post("/agent/plan", json=BODY, headers={"Authorization": "Bearer wrong-token"})
    assert response.status_code == 200
    assert response.json()["saved_trip"] is None
    assert repo.trips == []

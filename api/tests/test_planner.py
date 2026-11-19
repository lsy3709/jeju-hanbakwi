"""일정 짜기. AI 는 가짜로 바꿔 끼워, 우리 쪽 검사 로직만 확인합니다."""

from datetime import date

import pytest

from config import settings
from schemas import PlanRequest
from services import planner
from tests.fakes import FakeRepo, make_weather

START = date(2026, 12, 1)


def request(**kwargs):
    return PlanRequest(**{"message": "제주 여행", "days": 2, "start_date": START, **kwargs})


def all_spot_ids(plan):
    return [item["spot_id"] for day in plan["itinerary"] for item in day["items"]]


# ---------------------------------------------------------------- 규칙 방식

def test_rule_plan_shape():
    plan = planner.plan_trip(request(days=3), FakeRepo(), make_weather(False))
    assert plan["mode"] == "rule"
    assert [d["day"] for d in plan["itinerary"]] == [1, 2, 3]
    assert plan["itinerary"][0]["date"] == START
    ids = all_spot_ids(plan)
    assert len(ids) == len(set(ids)), "같은 장소가 두 번 들어가면 안 됩니다"
    assert set(ids) == {s["id"] for s in plan["sources"]}, "일정의 장소는 모두 sources 에 있어야 합니다"
    for day in plan["itinerary"]:
        assert 3 <= len(day["items"]) <= 4
        assert day["items"][1]["time"] == "점심"


def test_rule_plan_uses_indoor_on_rainy_day():
    repo = FakeRepo()
    plan = planner.plan_trip(request(), repo, make_weather(first_day_rainy=True))
    first, second = plan["itinerary"]
    assert first["weather"] == "비"
    sights = [repo.get_spot(i["spot_id"]) for i in first["items"] if i["time"] != "점심"]
    assert sights and all(s["indoor"] for s in sights)
    assert "실내" in plan["answer"]
    assert second["weather"] == "맑음"


def test_rule_plan_follows_theme_in_message():
    repo = FakeRepo()
    plan = planner.plan_trip(request(message="폭포 위주로 보고 싶어요", days=1), repo, make_weather(False))
    tags = [repo.get_spot(i)["theme_tags"] for i in all_spot_ids(plan)]
    assert any("폭포" in t for t in tags)


def test_rule_plan_includes_mentioned_spot():
    plan = planner.plan_trip(request(message="성산일출봉을 포함한 일정", days=1), FakeRepo(), make_weather(False))
    first = plan["itinerary"][0]["items"][0]
    assert first["title"] == "성산일출봉"
    assert "말씀하신" in first["reason"]


def test_rule_plan_without_weather_still_works():
    from services.weather import WeatherUnavailable

    def broken():
        raise WeatherUnavailable("down")

    plan = planner.plan_trip(request(days=1), FakeRepo(), broken)
    assert plan["itinerary"][0]["weather"] is None
    assert plan["itinerary"][0]["items"]


# ---------------------------------------------------------------- AI 방식 (AI 는 가짜)

@pytest.fixture
def with_ai_key(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "test-key")


def test_extract_json_ignores_decoration():
    text = '```json\n{"answer": "좋아요", "itinerary": []}\n```'
    assert planner.extract_json(text)["answer"] == "좋아요"
    with pytest.raises(ValueError):
        planner.extract_json("JSON 이 없는 답")


def test_ai_plan_keeps_only_spots_we_showed(with_ai_key):
    repo = FakeRepo()

    def fake_ai(req, repo_, get_weather, found):
        found[1] = repo.get_spot(1)   # AI 에게 보여 준 것
        found[10] = repo.get_spot(10)
        return (
            '{"answer": "동쪽 코스입니다.", "itinerary": [{"day": 1, "items": ['
            '{"time": "오전", "spot_id": 1, "reason": "일출"},'
            '{"time": "오후", "spot_id": 777, "reason": "지어낸 장소"},'   # 보여 준 적 없는 번호
            '{"time": "새벽", "spot_id": 10, "reason": "틀린 시간대"},'
            '{"time": "저녁", "spot_id": 1, "reason": "중복"},'
            '{"time": "오후", "spot_id": "10", "reason": "글자로 온 번호"}]}]}'
        )

    plan = planner.plan_trip(request(days=1), repo, make_weather(False), ask_ai=fake_ai)
    assert plan["mode"] == "ai"
    assert plan["answer"] == "동쪽 코스입니다."
    assert all_spot_ids(plan) == [1, 10]
    assert [i["title"] for i in plan["itinerary"][0]["items"]] == ["성산일출봉", "아쿠아플라넷 제주"]
    assert {s["id"] for s in plan["sources"]} == {1, 10}
    assert plan["itinerary"][0]["weather"] == "맑음"


def test_ai_plan_drops_days_beyond_request(with_ai_key):
    repo = FakeRepo()

    def fake_ai(req, repo_, get_weather, found):
        found.update({1: repo.get_spot(1), 2: repo.get_spot(2)})
        return '{"answer": "a", "itinerary": [{"day": 1, "items": [{"time": "오전", "spot_id": 1}]}, {"day": 2, "items": [{"time": "오전", "spot_id": 2}]}]}'

    plan = planner.plan_trip(request(days=1), repo, make_weather(False), ask_ai=fake_ai)
    assert len(plan["itinerary"]) == 1


@pytest.mark.parametrize(
    "ai_text",
    ["죄송합니다. 일정을 만들 수 없습니다.", '{"answer": "x", "itinerary": []}', '{"answer": "x", "itinerary": [{"day": 1, "items": [{"time": "오전", "spot_id": 999}]}]}'],
)
def test_falls_back_to_rule_when_ai_answer_is_unusable(with_ai_key, ai_text):
    plan = planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=lambda *a: ai_text)
    assert plan["mode"] == "rule"
    assert plan["itinerary"]


def test_falls_back_to_rule_when_ai_raises(with_ai_key):
    def broken(*args):
        raise RuntimeError("quota exceeded")

    plan = planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=broken)
    assert plan["mode"] == "rule"


def test_no_key_means_ai_is_never_called():
    def must_not_run(*args):
        raise AssertionError("키가 없는데 AI 를 불렀습니다")

    assert planner.plan_trip(request(), FakeRepo(), make_weather(False), ask_ai=must_not_run)["mode"] == "rule"


def test_plan_endpoint(client):
    response = client.post("/agent/plan", json={"message": "아이와 2일", "days": 2, "companions": "아이와", "start_date": "2026-12-01"})
    assert response.status_code == 200
    body = response.json()
    assert body["mode"] == "rule"
    assert len(body["itinerary"]) == 2
    assert body["itinerary"][0]["date"] == "2026-12-01"

    assert client.post("/agent/plan", json={"message": ""}).status_code == 422
    assert client.post("/agent/plan", json={"message": "x", "days": 4}).status_code == 422

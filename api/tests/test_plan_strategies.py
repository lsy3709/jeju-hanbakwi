"""일정 짜기 방식(전략)을 고르고 차례로 시도하는 부분, 그리고 말한 장소를 빠뜨리지 않는 규칙."""

# 확인하는 것: 키가 있으면 AI → 규칙 순서로, 없으면 규칙만 시도하는지(planner.choose_planners), 두 방식의 결과 모양이 같은지,
# 그리고 사용자가 이름을 말한 관광지를 규칙 방식이 조용히 빠뜨리지 않는지. 진짜 AI·DB 는 쓰지 않습니다.
from datetime import date

from config import settings
from schemas import PlanRequest
from services import planner
from services.plan_ai import AiPlanner
from services.plan_rule import RulePlanner, take_mentioned_for_day
from tests.fakes import FakeRepo, make_weather

START = date(2026, 12, 1)


def request(**kwargs):
    return PlanRequest(**{"message": "제주 여행", "days": 2, "start_date": START, **kwargs})


def titles(plan):
    return [item["title"] for day in plan["itinerary"] for item in day["items"]]


# ---------------------------------------------------------------- 방식 고르기

def test_without_ai_key_only_rule_planner_is_used(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "")
    planners = planner.choose_planners(FakeRepo(), make_weather(False))
    assert [p.name for p in planners] == ["rule"]


def test_with_ai_key_ai_comes_first_and_rule_is_the_fallback(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "test-key")
    planners = planner.choose_planners(FakeRepo(), make_weather(False))
    assert [p.name for p in planners] == ["ai", "rule"]
    assert isinstance(planners[0], AiPlanner) and isinstance(planners[1], RulePlanner)


def test_each_planner_returns_the_same_shape(monkeypatch):
    """어떤 방식이든 결과 모양이 같아야, 화면이 방식을 몰라도 그릴 수 있습니다."""
    repo = FakeRepo()

    def fake_ai(req, repo_, get_weather, found):
        found[1] = repo.get_spot(1)
        return '{"answer": "a", "itinerary": [{"day": 1, "items": [{"time": "오전", "spot_id": 1}]}]}'

    for one in (AiPlanner(repo, make_weather(False), ask=fake_ai), RulePlanner(repo, make_weather(False))):
        plan = one.plan(request(days=1))
        assert set(plan) == {"mode", "answer", "itinerary", "sources"}
        assert plan["mode"] == one.name
        assert set(plan["itinerary"][0]) == {"day", "date", "weather", "items"}


# ---------------------------------------------------------------- 말한 장소를 빠뜨리지 않기

def test_all_mentioned_places_fit_in_one_day():
    """예전에는 하루에 하나만 넣고 나머지를 조용히 뺐습니다."""
    plan = planner.plan_trip(request(message="성산일출봉, 만장굴, 비자림 꼭 넣어 주세요", days=1), FakeRepo(), make_weather(False))
    assert {"성산일출봉", "만장굴", "비자림"} <= set(titles(plan))


def test_mentioned_places_in_the_same_area_go_together():
    plan = planner.plan_trip(request(message="성산일출봉 섭지코지 협재해수욕장", days=2), FakeRepo(), make_weather(False))
    day1 = [i["title"] for i in plan["itinerary"][0]["items"]]
    day2 = [i["title"] for i in plan["itinerary"][1]["items"]]
    assert "성산일출봉" in day1 and "섭지코지" in day1  # 둘 다 동부
    assert "협재해수욕장" in day2  # 서부는 다음 날


def test_too_many_mentioned_places_are_reported_not_dropped_silently():
    message = "성산일출봉 만장굴 비자림 섭지코지 우도"
    plan = planner.plan_trip(request(message=message, days=1), FakeRepo(), make_weather(False))
    placed = set(titles(plan))
    missing = {"성산일출봉", "만장굴", "비자림", "섭지코지", "우도"} - placed
    assert len(missing) == 2  # 하루에 3곳까지
    assert "넣지 못한 곳" in plan["answer"]
    assert all(name in plan["answer"] for name in missing)


def test_take_mentioned_for_day():
    east1, east2, west = {"id": 1, "area": "동부"}, {"id": 2, "area": "동부"}, {"id": 3, "area": "서부"}

    left = [east1, west, east2]
    assert take_mentioned_for_day(left, is_last_day=False) == [east1, east2]
    assert left == [west]

    left = [east1, west, east2]
    assert take_mentioned_for_day(left, is_last_day=True) == [east1, west, east2]  # 마지막 날은 지역이 달라도 넣음
    assert left == []

    assert take_mentioned_for_day([], is_last_day=True) == []

"""일정 짜기의 경계 사례. 코드 분석(2026-11-20)에서 찾은 것들입니다."""

from datetime import date, datetime, timezone

import pytest

from config import settings
from schemas import PlanRequest
from services import planner
from tests.fakes import FakeRepo, make_weather

START = date(2026, 12, 1)


def request(**kwargs):
    return PlanRequest(**{"message": "제주 여행", "days": 2, "start_date": START, **kwargs})


# ---------------------------------------------------------------- 날짜

def test_korea_today_does_not_follow_server_clock():
    """배포한 서버는 세계 표준시로 돕니다. 한국 12월 2일 새벽 5시는 표준시로 12월 1일 저녁 8시입니다."""
    assert planner.korea_today(datetime(2026, 12, 1, 20, 0, tzinfo=timezone.utc)) == date(2026, 12, 2)
    assert planner.korea_today(datetime(2026, 12, 1, 14, 59, tzinfo=timezone.utc)) == date(2026, 12, 1)


def test_plan_without_start_date_starts_on_korea_today(monkeypatch):
    monkeypatch.setattr(planner, "korea_today", lambda now=None: START)
    plan = planner.plan_trip(PlanRequest(message="제주 여행", days=1), FakeRepo(), make_weather(first_day_rainy=True))
    assert plan["itinerary"][0]["date"] == START
    assert plan["itinerary"][0]["weather"] == "비"  # 날짜가 맞아야 그날 날씨가 붙습니다


# ---------------------------------------------------------------- 글에서 장소 이름 찾기

@pytest.mark.parametrize("message", ["우도 가고 싶어요", "우도랑 섭지코지", "우도하고 섭지코지"])
def test_two_letter_place_name_is_not_cut(message):
    """조사를 떼다가 "우도"의 끝 글자까지 떼면 한 글자가 되어 못 찾습니다."""
    titles = [s["title"] for s in planner.find_mentioned_spots(message, FakeRepo())]
    assert "우도" in titles


def test_more_particles_are_removed():
    titles = [s["title"] for s in planner.find_mentioned_spots("성산일출봉하고 만장굴이랑 가요", FakeRepo())]
    assert "성산일출봉" in titles and "만장굴" in titles


# ---------------------------------------------------------------- 시장

def test_market_theme_brings_a_market():
    """시장은 분류가 쇼핑이라 관광지 칸에서 빠지고 있었습니다. 시장을 말했을 때는 넣어야 합니다."""
    plan = planner.plan_trip(request(message="시장 구경하고 싶어요", days=1), FakeRepo(), make_weather(False))
    titles = [i["title"] for i in plan["itinerary"][0]["items"]]
    assert any("시장" in t for t in titles), titles


def test_shopping_is_still_excluded_without_market_theme():
    repo = FakeRepo()
    plan = planner.plan_trip(request(message="제주 여행", days=3), repo, make_weather(False))
    sights = [repo.get_spot(i["spot_id"]) for d in plan["itinerary"] for i in d["items"] if i["time"] != "점심"]
    assert all(s["category"] != "쇼핑" for s in sights)


# ---------------------------------------------------------------- AI 가 준 순서

def test_ai_items_are_sorted_by_time_of_day(monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "test-key")
    repo = FakeRepo()

    def fake_ai(req, repo_, get_weather, found):
        found.update({1: repo.get_spot(1), 3: repo.get_spot(3), 10: repo.get_spot(10)})
        return (
            '{"answer": "a", "itinerary": [{"day": 1, "items": ['
            '{"time": "저녁", "spot_id": 1}, {"time": "오전", "spot_id": 10}, {"time": "오후", "spot_id": 3}]}]}'
        )

    plan = planner.plan_trip(request(days=1), repo, make_weather(False), ask_ai=fake_ai)
    assert [i["time"] for i in plan["itinerary"][0]["items"]] == ["오전", "오후", "저녁"]

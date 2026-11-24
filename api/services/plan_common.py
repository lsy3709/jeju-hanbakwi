"""일정 짜기에서 두 방식(AI · 규칙)이 함께 쓰는 것들."""

# 쓰는 곳: plan_ai.py · plan_rule.py(두 방식) · usage.py(한국 날짜 계산). 이 파일은 DB 도 AI 도 부르지 않습니다.
# 낱말: Protocol = "이 이름의 값과 함수를 갖추면 같은 종류로 본다"는 약속 틀입니다. 상속하지 않아도 모양만 맞으면 됩니다.
from datetime import date, datetime, timedelta, timezone
from typing import Protocol

from schemas import PlanRequest
from services.weather import WeatherUnavailable

KOREA = timezone(timedelta(hours=9))  # 한국 시간 = 세계 표준시 + 9시간 (서머타임 없음)


class Planner(Protocol):
    """일정을 짜는 방식 하나. (전략 패턴의 "전략")

    AI 로 짜든 규칙으로 짜든, plan(request) 를 부르면 같은 모양의 결과가 나옵니다.
    그래서 planner.py 는 "어떤 방식인지" 몰라도 차례로 시도해 볼 수 있습니다.
    새 방식(예: 다른 AI)을 더하고 싶으면 이 모양의 클래스를 하나 더 만들면 됩니다.
    """

    name: str

    def plan(self, request: PlanRequest) -> dict:
        """{"mode", "answer", "itinerary", "sources"} 를 돌려줍니다. 못 짜면 오류를 냅니다."""
        ...


def korea_today(now: datetime | None = None) -> date:
    """한국 기준 오늘 날짜.

    date.today() 는 "서버가 있는 곳"의 날짜입니다. 배포한 서버는 세계 표준시로 돌기 때문에,
    한국의 자정~오전 9시에는 어제 날짜가 나와 일정과 날씨가 하루씩 밀립니다.
    """
    return (now or datetime.now(timezone.utc)).astimezone(KOREA).date()


# 여행 날짜 목록. 시작일을 안 정했으면 한국 기준 오늘부터, days 일 동안 하루씩 더해 만듭니다.
def trip_dates(request: PlanRequest) -> list[date]:
    start = request.start_date or korea_today()
    return [start + timedelta(days=i) for i in range(request.days)]


def weather_by_date(get_weather) -> dict[str, dict]:
    """날짜 → 그날 날씨(제주시 기준). 날씨를 못 받으면 빈 사전."""
    try:
        weather = get_weather()
    except WeatherUnavailable:
        return {}
    # areas[0] 은 첫 지역(제주시)입니다. 날씨를 못 받아도 일정은 짤 수 있으므로 오류 대신 빈 사전을 돌려줍니다.
    days = weather["areas"][0]["days"] if weather["areas"] else []
    return {str(day["date"]): day for day in days}


def brief(spot: dict) -> dict:
    """AI 에게는 관광지의 핵심만 줍니다. (글자 수 = 비용)"""
    return {
        "id": spot["id"],
        "title": spot["title"],
        "category": spot["category"],
        "area": spot["area"],
        "one_liner": spot["one_liner"],
        "theme_tags": spot["theme_tags"],
        "indoor": spot["indoor"],
    }

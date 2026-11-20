"""여행 일정 짜기의 입구.

일정을 짜는 방식은 두 가지이고, 각각 파일이 따로 있습니다.

  1) AI 방식   services/plan_ai.py    AI 가 도구를 스스로 불러 짭니다        → mode "ai"
  2) 규칙 방식 services/plan_rule.py  같은 데이터로 정해진 규칙에 따라 짭니다 → mode "rule"

이 파일은 "어떤 방식을 어떤 순서로 시도할지"만 정합니다. (전략 패턴)
앞의 방식이 실패하면 다음 방식으로 넘어가므로, AI 가 안 되는 날에도 서비스는 답을 줍니다.
어느 쪽이든 "우리 DB 에 있는 관광지만" 일정에 넣습니다.
"""

import logging

from config import settings
from schemas import PlanRequest
from services.plan_ai import AiPlanner, ask_gemini, build_plan_from_ai, extract_json  # noqa: F401
from services.plan_common import Planner, korea_today  # noqa: F401
from services.plan_rule import RulePlanner, find_mentioned_spots  # noqa: F401

log = logging.getLogger("planner")


def choose_planners(repo, get_weather, ask_ai=ask_gemini) -> list[Planner]:
    """지금 쓸 수 있는 방식을, 시도할 순서대로 돌려줍니다."""
    planners: list[Planner] = []
    if settings.gemini_api_key:  # 키가 없으면 AI 방식은 아예 시도하지 않습니다
        planners.append(AiPlanner(repo, get_weather, ask=ask_ai))
    planners.append(RulePlanner(repo, get_weather))  # 마지막 보루: 바깥 서비스 없이도 동작
    return planners


def plan_trip(request: PlanRequest, repo, get_weather, ask_ai=ask_gemini) -> dict:
    """앞 방식부터 차례로 시도하고, 처음 성공한 결과를 돌려줍니다."""
    planners = choose_planners(repo, get_weather, ask_ai)
    for planner in planners[:-1]:
        try:
            return planner.plan(request)
        except Exception as error:  # AI 쪽 문제(키·한도·시간 초과·이상한 답)는 무엇이든 다음 방식으로 넘깁니다
            log.warning("%s 방식 실패, 다음 방식으로 넘어갑니다: %s", planner.name, error)
    return planners[-1].plan(request)

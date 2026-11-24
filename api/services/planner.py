"""여행 일정 짜기의 입구.

일정을 짜는 방식은 두 가지이고, 각각 파일이 따로 있습니다.

  1) AI 방식   services/plan_ai.py    AI 가 도구를 스스로 불러 짭니다        → mode "ai"
  2) 규칙 방식 services/plan_rule.py  같은 데이터로 정해진 규칙에 따라 짭니다 → mode "rule"

이 파일은 "어떤 방식을 어떤 순서로 시도할지"만 정합니다. (전략 패턴)
앞의 방식이 실패하면 다음 방식으로 넘어가므로, AI 가 안 되는 날에도 서비스는 답을 줍니다.
사용자가 자기 AI 키를 보냈으면 그 키로 먼저 시도합니다. 그 키는 이 요청에만 쓰고 저장하지도, 로그에 남기지도 않습니다.
어느 쪽이든 "우리 DB 에 있는 관광지만" 일정에 넣습니다.
"""

# 층: routers/agent.py 가 plan_trip 을 부르면 → AiPlanner(plan_ai.py)를 먼저, 안 되면 RulePlanner(plan_rule.py)를 부릅니다.
# 아래 `# noqa: F401` 줄은 "여기서 안 쓰는 것 같아도 지우지 말라"는 표시입니다. 테스트가 planner.ask_gemini 처럼 이 파일 이름으로 불러 씁니다.
# 낱말: 대체 경로(fallback) = 앞의 방법이 실패했을 때 대신 쓰는 방법.
import logging

from config import settings
from schemas import PlanRequest
from services.plan_ai import AiPlanner, ask_gemini, build_plan_from_ai, extract_json  # noqa: F401
from services.plan_common import Planner, korea_today  # noqa: F401
from services.plan_rule import RulePlanner, find_mentioned_spots  # noqa: F401

log = logging.getLogger("planner")

USER_KEY_NOTICE = "넣어 주신 AI 키로는 일정을 받지 못해 다른 방식으로 대신 짰어요. 설정에서 키를 확인해 주세요."


def auto_title(message: str) -> str:
    """자동 저장할 일정의 제목. 요청 글을 한 줄로 만들어 앞 30자만 씁니다."""
    one_line = " ".join(message.split())
    return one_line if len(one_line) <= 30 else one_line[:30] + "…"


def hide_key(text: str, key: str | None) -> str:
    """오류 글에 키가 섞여 있으면 가립니다. (키를 로그에 남기지 않기 위해)"""
    return text.replace(key, "(키 가림)") if key else text


def choose_planners(repo, get_weather, ask_ai=ask_gemini, user_key: str | None = None) -> list[Planner]:
    """지금 쓸 수 있는 방식을, 시도할 순서대로 돌려줍니다. 사용자 키 → 서버 키 → 규칙."""
    planners: list[Planner] = []
    if user_key:  # 사용자가 보낸 자기 키가 있으면 그 키로 먼저
        planners.append(AiPlanner(repo, get_weather, ask=ask_ai, api_key=user_key))
    if settings.gemini_api_key:  # 키가 없으면 AI 방식은 아예 시도하지 않습니다
        planners.append(AiPlanner(repo, get_weather, ask=ask_ai))
    planners.append(RulePlanner(repo, get_weather))  # 마지막 보루: 바깥 서비스 없이도 동작
    return planners


def plan_trip(request: PlanRequest, repo, get_weather, ask_ai=ask_gemini, user_key: str | None = None) -> dict:
    """앞 방식부터 차례로 시도하고, 처음 성공한 결과를 돌려줍니다.

    사용자 키로 한 시도가 실패해 다른 방식으로 대신했으면 결과의 notice 에 안내 글을 담습니다.
    """
    # planners[-1] 은 항상 규칙 방식이고 planners[:-1] 은 그 앞의 AI 방식들입니다.
    # AI 방식을 차례로 시도해 처음 성공하면 멈추고(break), 모두 실패하면 아래에서 규칙 방식으로 짭니다.
    planners = choose_planners(repo, get_weather, ask_ai, user_key)
    result, user_key_failed, winner, tried = None, False, planners[-1], []
    for planner in planners[:-1]:
        tried.append(planner)
        try:
            result = planner.plan(request)
            winner = planner
            break
        except Exception as error:  # AI 쪽 문제(키·한도·시간 초과·이상한 답)는 무엇이든 다음 방식으로 넘깁니다
            if getattr(planner, "api_key", None):
                user_key_failed = True
            log.warning("%s 방식 실패, 다음 방식으로 넘어갑니다: %s", planner.name, hide_key(str(error), user_key))
    # 규칙 방식은 바깥 서비스를 부르지 않아 여기서는 오류를 잡지 않습니다.
    if result is None:
        result = planners[-1].plan(request)
    result["notice"] = USER_KEY_NOTICE if user_key_failed else None
    result["usage"] = usage_of(winner, tried)
    return result


def usage_of(winner, tried: list) -> dict:
    """이번 요청이 쓴 양. 사용량 기록(ai_usage 표)에 적을 값입니다.

    tried 는 시도한 AI 방식들(실패한 것 포함)입니다. 실패한 시도에서 쓴 토큰도 쓴 것이므로 모두 더합니다.
    key_source: user(사용자가 보낸 키) · server(서버 설정의 키) · none(AI 를 한 번도 부르지 않음)
      일정을 짠 방식의 키를 적고, 규칙으로 짰으면 마지막으로 시도한 AI 의 키를 적습니다.
    """
    names = ("ai_calls", "tokens_in", "tokens_out", "tokens_total")
    total = {name: sum(int((p.last_usage or {}).get(name, 0)) for p in tried) for name in names}
    who = winner if winner.name == "ai" else (tried[-1] if tried else None)
    source = "none" if who is None else ("user" if who.api_key else "server")
    return {"key_source": source, **total}

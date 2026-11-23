"""AI 일정 짜기 주소. 누구나 쓸 수 있습니다.

여기서는 요청을 받아 넘기고 결과를 돌려주기만 합니다. 일정을 짜는 일은 services/planner.py 가 합니다.

X-Gemini-Key 헤더: 사용자가 설정 화면에 넣은 자기 AI 키. 이 요청에만 쓰고 저장하지도, 로그에 남기지도 않습니다.
로그인한 채로 부르면 만든 일정을 그 사람의 "내 여행"에 자동으로 저장합니다(로그인은 선택).
부를 때마다 사용량 한 줄을 적습니다(누가 · 어떤 방식으로 · 토큰을 얼마나). 요청 글과 키는 적지 않습니다.
"""

import logging
import time
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request
from fastapi.encoders import jsonable_encoder

from auth import get_optional_user
from deps import get_ai_asker, get_key_checker, get_weather_service
from repo import get_repo
from schemas import KeyCheck, PlanRequest, PlanResponse, User
from services import planner
from services.photos import with_photo_addresses

router = APIRouter(tags=["AI 일정"])
log = logging.getLogger("agent")

# 키의 모양만 봅니다(영문 · 숫자 · _ · - · . 20~200자). 맞는 키인지는 AI 서비스가 판단합니다.
# 마침표는 "AQ." 로 시작하는 새 형식의 키에 들어 있습니다.
KEY_PATTERN = r"^[A-Za-z0-9_.\-]{20,200}$"
UserKey = Annotated[str | None, Header(alias="X-Gemini-Key", pattern=KEY_PATTERN)]
RequiredUserKey = Annotated[str, Header(alias="X-Gemini-Key", pattern=KEY_PATTERN)]


@router.post("/agent/plan", response_model=PlanResponse)
def plan(
    body: PlanRequest,
    request: Request,
    user_key: UserKey = None,
    repo=Depends(get_repo),
    get_weather_fn=Depends(get_weather_service),
    ask_ai=Depends(get_ai_asker),
    user: User | None = Depends(get_optional_user),
):
    started = time.monotonic()
    result = planner.plan_trip(body, repo, get_weather_fn, ask_ai=ask_ai, user_key=user_key)
    record_usage(repo, user, body, result, int((time.monotonic() - started) * 1000))
    result["sources"] = with_photo_addresses(result["sources"], request)
    result["saved_trip"] = save_for(user, body, result, repo)
    return result


def record_usage(repo, user: User | None, body: PlanRequest, result: dict, duration_ms: int) -> None:
    """이번 요청의 사용량을 한 줄 적습니다. 적지 못해도 일정은 그대로 돌려줍니다."""
    used = result.pop("usage")   # 응답에는 싣지 않습니다
    row = {"user_id": user.id if user else None, "mode": result["mode"], "days": body.days, "duration_ms": duration_ms, **used}
    try:
        repo.add_ai_usage(row)
    except Exception as error:
        log.warning("AI 사용량 기록 실패(일정은 그대로 돌려줍니다): %s", error)


def save_for(user: User | None, body: PlanRequest, result: dict, repo) -> dict | None:
    """로그인한 사용자의 일정을 "내 여행"에 저장하고 {id, title} 을 돌려줍니다. 저장하지 않았으면 None.

    저장은 덤입니다. 로그인하지 않았거나, 이용 정지거나, 저장에 실패해도 일정은 그대로 돌려줍니다.
    """
    if user is None:
        return None
    try:
        if repo.is_suspended(user.id):
            return None
        # jsonable_encoder: 날짜 같은 값을 DB 에 넣을 수 있는 글자로 바꿉니다.
        trip = repo.add_trip(user.id, planner.auto_title(body.message), jsonable_encoder(result["itinerary"]))
    except Exception as error:
        log.warning("일정 자동 저장 실패(일정은 그대로 돌려줍니다): %s", error)
        return None
    return {"id": trip["id"], "title": trip["title"]}


@router.post("/agent/key-check", response_model=KeyCheck)
def key_check(user_key: RequiredUserKey, check=Depends(get_key_checker)):
    """설정 화면의 "확인" 단추. 키가 쓸 수 있는 키인지만 알려 주고, 키는 저장하지 않습니다."""
    try:
        ok = check(user_key)
    except Exception as error:  # 키 문제가 아니라 AI 서비스에 닿지 못한 경우
        log.warning("AI 키 확인 실패: %s", planner.hide_key(str(error), user_key))
        return {"ok": False, "message": "AI 서비스에 닿지 못했어요. 잠시 뒤 다시 확인해 주세요."}
    if ok:
        return {"ok": True, "message": "쓸 수 있는 키예요."}
    return {"ok": False, "message": "쓸 수 없는 키예요. 키를 다시 확인해 주세요."}

"""AI 일정 짜기 주소. 누구나 쓸 수 있습니다.

여기서는 요청을 받아 넘기고 결과를 돌려주기만 합니다. 일정을 짜는 일은 services/planner.py 가 합니다.
"""

from fastapi import APIRouter, Depends, Request

from deps import get_weather_service
from repo import get_repo
from schemas import PlanRequest, PlanResponse
from services import planner
from services.photos import with_photo_addresses

router = APIRouter(tags=["AI 일정"])


@router.post("/agent/plan", response_model=PlanResponse)
def plan(body: PlanRequest, request: Request, repo=Depends(get_repo), get_weather_fn=Depends(get_weather_service)):
    result = planner.plan_trip(body, repo, get_weather_fn)
    result["sources"] = with_photo_addresses(result["sources"], request)
    return result

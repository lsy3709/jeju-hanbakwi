"""운영 확인용 주소.

  /health  서버가 켜져 있는지만 봅니다. (배포 서비스가 주기적으로 부르는 용도)
  /status  무엇이 연결됐고 무엇이 빠졌는지 봅니다. 배포한 뒤 문제가 생기면 가장 먼저 여는 주소입니다.

/status 는 "있다/없다"만 알려 줍니다. 키 값 자체는 절대 내보내지 않습니다.
"""

# 층: 이 파일(주소) → repo.py 로 DB 에 한 번 닿아 보고, config.settings 로 키가 있는지만 봅니다.
# 낱말: 헬스체크 = "살아 있나요?"를 주기적으로 묻는 확인. 배포 서비스가 /health 를 이 용도로 부릅니다.
import logging

from fastapi import APIRouter, Depends

from config import settings
from repo import get_repo
from schemas import Status
from services.photos import count_photos

log = logging.getLogger("system")
router = APIRouter(tags=["운영"])


@router.get("/health")
def health():
    return {"status": "ok"}


# 아래 `_, spots = ...` 의 `_` 는 "이 값은 안 쓴다"는 표시입니다. 목록은 버리고 전체 개수만 받습니다.
@router.get("/status", response_model=Status)
def status(repo=Depends(get_repo)):
    try:
        _, spots = repo.list_spots(size=1)
        database = "ok"
    except Exception as error:  # 고장 났을 때 보려고 만든 주소라, 스스로는 죽지 않아야 합니다
        log.warning("DB 확인 실패: %s", error)
        database, spots = "error", None
    return {
        "database": database,  # DB 에 닿는지
        "spots": spots,  # 관광지 수 (0 이면 데이터를 아직 안 넣은 것)
        "ai": "ai" if settings.gemini_api_key else "rule",  # 일정을 AI 로 짜는지, 규칙으로만 짜는지
        "login": "on" if settings.supabase_url and settings.supabase_service_role_key else "off",
        "photos": count_photos(),  # 서버에 들어 있는 사진 수
    }

"""운영 확인용 주소.

  /health  서버가 켜져 있는지만 봅니다. (배포 서비스가 주기적으로 부르는 용도)
"""

from fastapi import APIRouter

router = APIRouter(tags=["운영"])


@router.get("/health")
def health():
    return {"status": "ok"}

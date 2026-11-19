"""로그인 확인.

화면(웹·앱)이 구글 로그인으로 받은 토큰을 `Authorization: Bearer <토큰>` 으로 보내면,
서버가 Supabase 에 "이 토큰 주인이 누구냐"고 물어 사용자를 확인합니다.
화면이 보낸 사용자 ID 를 그대로 믿지 않는 것이 핵심입니다.
"""

import httpx
from fastapi import Header, HTTPException

from config import settings
from schemas import User


def verify_token(token: str) -> User | None:
    """Supabase 에 토큰을 확인받습니다. 틀리거나 만료됐으면 None."""
    if not settings.supabase_url:
        return None
    try:
        response = httpx.get(
            f"{settings.supabase_url}/auth/v1/user",
            headers={"apikey": settings.supabase_service_role_key, "Authorization": f"Bearer {token}"},
            timeout=5,
        )
    except httpx.HTTPError:
        return None
    if response.status_code != 200:
        return None
    data = response.json()
    if not data.get("id"):
        return None
    return User(id=data["id"], email=data.get("email"))


def get_current_user(authorization: str | None = Header(default=None)) -> User:
    """로그인이 필요한 주소에 붙이는 문지기. 통과 못 하면 401."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    user = verify_token(authorization[7:].strip())
    if user is None:
        raise HTTPException(status_code=401, detail="로그인 정보가 올바르지 않거나 만료되었습니다.")
    return user

"""로그인 확인.

화면(웹·앱)이 구글 로그인으로 받은 토큰을 `Authorization: Bearer <토큰>` 으로 보내면,
서버가 Supabase 에 "이 토큰 주인이 누구냐"고 물어 사용자를 확인합니다.
화면이 보낸 사용자 ID 를 그대로 믿지 않는 것이 핵심입니다.
"""

# 이 파일은 "문지기" 함수 모음입니다. routers/ 의 주소가 Depends(...) 로 끼워 쓰면,
# 주소 함수가 실행되기 전에 먼저 이 함수들이 불려 로그인 여부를 가려 줍니다.
# 안에서는 Supabase 에 토큰을 물어보고(verify_token), repo.py 로 이용 정지 여부를 확인합니다.
# 낱말: 토큰 = 로그인했다는 증표 글자. 401 = "누구인지 모름", 403 = "누구인지는 알지만 허락 안 됨".
import httpx
from fastapi import Depends, Header, HTTPException

from config import settings
from repo import get_repo
from schemas import User


# 연결은 한 번만 만들어 계속 씁니다. (repo.py 의 Supabase 연결과 같은 생각)
# httpx.get(...) 을 그냥 부르면 부를 때마다 연결과 보안 설정을 새로 만들어 매번 0.2초쯤 더 걸립니다.
_http = httpx.Client(timeout=5)


def verify_token(token: str) -> User | None:
    """Supabase 에 토큰을 확인받습니다. 틀리거나 만료됐으면 None."""
    # Supabase 주소가 설정돼 있지 않으면 확인할 곳이 없으니 "로그인 안 한 것"으로 봅니다.
    if not settings.supabase_url:
        return None
    # 네트워크가 끊기거나 늦어도 서버가 죽지 않게, 오류는 "확인 실패(None)"로 바꿉니다.
    try:
        response = _http.get(
            f"{settings.supabase_url}/auth/v1/user",
            headers={"apikey": settings.supabase_service_role_key, "Authorization": f"Bearer {token}"},
        )
    except httpx.HTTPError:
        return None
    if response.status_code != 200:
        return None
    data = response.json()
    if not data.get("id"):
        return None
    return User(id=data["id"], email=data.get("email"))


# Header(default=None) 은 요청 머리글(헤더)의 Authorization 값을 FastAPI 가 대신 꺼내 넣어 준다는 뜻입니다.
# `str | None` 은 "글자이거나, 없을 수 있다(None)"는 타입 표시입니다.
def get_current_user(authorization: str | None = Header(default=None)) -> User:
    """로그인이 필요한 주소에 붙이는 문지기. 통과 못 하면 401."""
    # authorization[7:] 은 앞의 "Bearer "(7글자)를 잘라 낸 토큰 부분입니다.
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    user = verify_token(authorization[7:].strip())
    if user is None:
        raise HTTPException(status_code=401, detail="로그인 정보가 올바르지 않거나 만료되었습니다.")
    return user


def get_optional_user(authorization: str | None = Header(default=None)) -> User | None:
    """로그인이 "선택"인 주소에 붙입니다. 로그인했으면 그 사용자, 아니면 None (401 을 내지 않음).

    토큰이 틀렸거나 만료된 경우에도 None 입니다. 로그인 없이도 되는 일을 토큰 때문에 막지 않으려는 것입니다.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    return verify_token(authorization[7:].strip())


def is_admin(user: User) -> bool:
    """서버 환경변수 ADMIN_EMAILS 에 적힌 이메일인가. 이메일은 Supabase 가 확인해 준 값만 씁니다."""
    # 대소문자가 달라도 같은 이메일로 보도록 둘 다 소문자로 맞춰 비교합니다.
    return bool(user.email) and user.email.lower() in settings.admin_emails


def get_active_user(user: User = Depends(get_current_user), repo=Depends(get_repo)) -> User:
    """로그인했고 이용 정지가 아닌 사람. 찜·일정 주소에 붙입니다. 정지면 403."""
    # Depends(get_current_user) 는 "먼저 그 문지기를 통과시킨 결과를 여기 넣어 달라"는 뜻입니다.
    # Depends(get_repo) 는 DB 창구를 대신 넣어 주며, 테스트에서는 가짜 DB 로 바꿔 끼웁니다.
    if repo.is_suspended(user.id):
        raise HTTPException(status_code=403, detail="이용이 정지된 계정입니다. 관리자에게 문의해 주세요.")
    return user


def get_admin_user(user: User = Depends(get_current_user)) -> User:
    """관리자 주소에 붙이는 문지기. 로그인은 했지만 관리자가 아니면 403."""
    if not is_admin(user):
        raise HTTPException(status_code=403, detail="관리자만 쓸 수 있습니다.")
    return user

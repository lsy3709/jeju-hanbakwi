"""환경변수(.env)를 한 곳에서 읽습니다.

비밀 값은 코드에 적지 않고 api/.env 파일에 둡니다. (.env 는 git 에 올라가지 않습니다)
처음에는 .env.example 을 .env 로 복사해서 값을 채우세요.
"""

# 서버의 다른 파일은 환경변수를 직접 읽지 않고, 여기서 만든 `settings` 하나만 가져다 씁니다.
# 비밀 키를 이 파일로만 읽게 하면 "키가 어디서 오는지"가 한 곳에 모이고,
# 코드나 git 에 키가 새어 들어갈 일이 줄어듭니다.
# 낱말: 환경변수 = 프로그램 밖(.env 파일, 배포 설정)에서 넣어 주는 설정 값.
import os
from pathlib import Path

from dotenv import load_dotenv

# 어디서 실행하든 api/.env 를 읽도록 이 파일 위치를 기준으로 찾습니다.
load_dotenv(Path(__file__).parent / ".env")


def _env(name: str, default: str = "") -> str:
    # strip() 은 값 앞뒤의 공백·줄바꿈을 지웁니다. 복사해 붙일 때 딸려 온 공백으로 키가 틀리는 일을 막습니다.
    return os.getenv(name, default).strip()


# 설정 값을 모아 둔 상자입니다. 아래 settings 한 개만 만들어 모든 파일이 함께 씁니다.
class Settings:
    # Supabase (DB + 로그인 확인)
    supabase_url = _env("SUPABASE_URL").rstrip("/")
    supabase_service_role_key = _env("SUPABASE_SERVICE_ROLE_KEY")

    # AI (없으면 규칙으로 일정을 짭니다)
    gemini_api_key = _env("GEMINI_API_KEY")
    gemini_model = _env("GEMINI_MODEL", "gemini-3.8-flash")

    # 한국관광공사 TourAPI (데이터 가져오기 도구에서만 씁니다)
    tour_api_key = _env("TOUR_API_KEY")
    tour_api_base = _env("TOUR_API_BASE", "https://apis.data.go.kr/B551011/KorService2").rstrip("/")

    # 이 서버의 공개 주소. 보통은 비워 둡니다(요청이 들어온 주소를 그대로 씀).
    # 배포 후 사진 주소가 http 로 잘못 나올 때만 "https://내서버.vercel.app" 처럼 넣습니다.
    public_api_url = _env("PUBLIC_API_URL").rstrip("/")

    # 이 서버를 불러도 되는 화면 주소들(쉼표로 구분). 배포한 웹·앱 주소를 여기에 추가합니다.
    allowed_origins = [o.strip() for o in _env("ALLOWED_ORIGINS", "http://localhost:3000").split(",") if o.strip()]

    # 관리자 이메일(쉼표로 구분). 이 이메일로 구글 로그인한 사람만 /admin 주소를 쓸 수 있습니다.
    # 비밀 값은 아니지만 서버에만 둡니다(화면이 "나는 관리자"라고 우기지 못하게 서버가 판단).
    admin_emails = [e.strip().lower() for e in _env("ADMIN_EMAILS").split(",") if e.strip()]


settings = Settings()

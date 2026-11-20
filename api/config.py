"""환경변수(.env)를 한 곳에서 읽습니다.

비밀 값은 코드에 적지 않고 api/.env 파일에 둡니다. (.env 는 git 에 올라가지 않습니다)
처음에는 .env.example 을 .env 로 복사해서 값을 채우세요.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

# 어디서 실행하든 api/.env 를 읽도록 이 파일 위치를 기준으로 찾습니다.
load_dotenv(Path(__file__).parent / ".env")


def _env(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


class Settings:
    # Supabase (DB)
    supabase_url = _env("SUPABASE_URL").rstrip("/")
    supabase_service_role_key = _env("SUPABASE_SERVICE_ROLE_KEY")

    # 이 서버를 불러도 되는 화면 주소들(쉼표로 구분). 배포한 웹·앱 주소를 여기에 추가합니다.
    allowed_origins = [o.strip() for o in _env("ALLOWED_ORIGINS", "http://localhost:3000").split(",") if o.strip()]


settings = Settings()

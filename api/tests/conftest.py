# conftest.py 는 pytest 가 테스트보다 먼저 자동으로 읽는 공용 준비 파일입니다. 여기 만든 fixture(준비물)는
# 테스트 함수가 인자 이름만 적으면 pytest 가 알아서 만들어 넣어 줍니다.
# 이 파일의 목적: 진짜 DB·AI·키를 쓰지 않고 FakeRepo(가짜 DB)와 가짜 날씨로 서버를 돌려 보게 하는 것입니다.
# 낱말: dependency_overrides = FastAPI 의 Depends 자리에 다른 함수를 끼워 넣는 장치(운영 코드는 그대로 둠).
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# api 폴더를 import 경로에 넣어 `import main` 이 되게 합니다.
sys.path.insert(0, str(Path(__file__).parent.parent))

import main  # noqa: E402
from auth import get_current_user  # noqa: E402
from config import settings  # noqa: E402
from repo import get_repo  # noqa: E402
from schemas import User  # noqa: E402
from tests.fakes import FakeRepo, make_weather  # noqa: E402

# 테스트에서 쓰는 가짜 사용자들. 서로 다른 사람이라 "남의 것은 안 보인다"를 확인할 때 씁니다.
ALICE = User(id="00000000-0000-0000-0000-00000000000a", email="alice@example.com")
BOB = User(id="00000000-0000-0000-0000-00000000000b", email="bob@example.com")
ADMIN = User(id="00000000-0000-0000-0000-0000000000ad", email="admin@example.com")


# autouse=True 는 모든 테스트에 자동 적용된다는 뜻입니다. monkeypatch 는 테스트가 끝나면 값을 원래대로 되돌려 줍니다.
@pytest.fixture(autouse=True)
def no_real_keys(monkeypatch):
    """테스트는 진짜 AI·Supabase 를 부르지 않습니다. (PC 에 키가 있어도 비웁니다)"""
    monkeypatch.setattr(settings, "gemini_api_key", "")
    monkeypatch.setattr(settings, "supabase_url", "")
    monkeypatch.setattr(settings, "supabase_service_role_key", "")
    monkeypatch.setattr(settings, "admin_emails", ["admin@example.com"])


@pytest.fixture
def repo():
    return FakeRepo()


# 가짜 DB 와 가짜 날씨를 끼운 "서버에 요청 보내는 도구"입니다. yield 앞은 준비, 뒤(clear)는 테스트 끝난 뒤의 정리입니다.
@pytest.fixture
def client(repo):
    main.app.dependency_overrides[get_repo] = lambda: repo
    main.app.dependency_overrides[main.get_weather_service] = lambda: make_weather(first_day_rainy=False)
    yield TestClient(main.app)
    main.app.dependency_overrides.clear()


@pytest.fixture
def login():
    """login(ALICE) 처럼 부르면 그 사용자로 로그인한 것으로 칩니다."""

    # 진짜 토큰 확인(Supabase 호출) 대신 "항상 이 사용자"를 돌려주는 함수를 끼웁니다.
    def _login(user: User):
        main.app.dependency_overrides[get_current_user] = lambda: user

    return _login

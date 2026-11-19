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

ALICE = User(id="00000000-0000-0000-0000-00000000000a", email="alice@example.com")
BOB = User(id="00000000-0000-0000-0000-00000000000b", email="bob@example.com")


@pytest.fixture(autouse=True)
def no_real_keys(monkeypatch):
    """테스트는 진짜 AI·Supabase 를 부르지 않습니다. (PC 에 키가 있어도 비웁니다)"""
    monkeypatch.setattr(settings, "gemini_api_key", "")
    monkeypatch.setattr(settings, "supabase_url", "")
    monkeypatch.setattr(settings, "supabase_service_role_key", "")


@pytest.fixture
def repo():
    return FakeRepo()


@pytest.fixture
def client(repo):
    main.app.dependency_overrides[get_repo] = lambda: repo
    main.app.dependency_overrides[main.get_weather_service] = lambda: make_weather(first_day_rainy=False)
    yield TestClient(main.app)
    main.app.dependency_overrides.clear()


@pytest.fixture
def login():
    """login(ALICE) 처럼 부르면 그 사용자로 로그인한 것으로 칩니다."""

    def _login(user: User):
        main.app.dependency_overrides[get_current_user] = lambda: user

    return _login

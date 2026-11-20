import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# api 폴더를 import 경로에 넣어 `import main` 이 되게 합니다.
sys.path.insert(0, str(Path(__file__).parent.parent))

import main  # noqa: E402
from config import settings  # noqa: E402
from repo import get_repo  # noqa: E402
from tests.fakes import FakeRepo, make_weather  # noqa: E402


@pytest.fixture(autouse=True)
def no_real_keys(monkeypatch):
    """테스트는 진짜 Supabase 를 부르지 않습니다. (PC 에 키가 있어도 비웁니다)"""
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

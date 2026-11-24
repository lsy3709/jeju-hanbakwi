"""운영 확인용 주소 /status. 배포한 뒤 "무엇이 연결됐고 무엇이 빠졌는지"를 한눈에 봅니다."""

# 가장 중요한 것은 세 번째와 네 번째입니다: /status 가 비밀 키 값을 절대 내보내지 않는지, DB 가 고장 나도 스스로는 200 으로 답하는지.
from config import settings


def test_status_reports_what_is_connected(client, monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "test-key")
    body = client.get("/status").json()
    assert body["database"] == "ok"
    assert body["spots"] == 68
    assert body["ai"] == "ai"
    assert body["login"] == "off"  # 테스트에서는 Supabase 주소가 비어 있음
    assert body["photos"] == 55


def test_status_without_ai_key_says_rule(client):
    assert client.get("/status").json()["ai"] == "rule"


def test_status_never_shows_secret_values(client, monkeypatch):
    monkeypatch.setattr(settings, "gemini_api_key", "super-secret-key")
    monkeypatch.setattr(settings, "supabase_service_role_key", "another-secret")
    text = client.get("/status").text
    assert "super-secret-key" not in text and "another-secret" not in text


def test_status_survives_a_broken_database(client):
    import main
    from repo import get_repo

    class BrokenRepo:
        def list_spots(self, **kwargs):
            raise RuntimeError("connection refused")

    main.app.dependency_overrides[get_repo] = lambda: BrokenRepo()
    response = client.get("/status")
    assert response.status_code == 200  # 고장 났을 때 보려고 만든 주소라, 스스로는 죽지 않아야 합니다
    assert response.json()["database"] == "error"
    assert response.json()["spots"] is None

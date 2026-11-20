"""운영 확인용 주소 /status. 배포한 뒤 "무엇이 연결됐고 무엇이 빠졌는지"를 한눈에 봅니다."""

from config import settings


def test_status_reports_what_is_connected(client):
    body = client.get("/status").json()
    assert body["database"] == "ok"
    assert body["spots"] == 68
    assert body["photos"] == 55


def test_status_never_shows_secret_values(client, monkeypatch):
    monkeypatch.setattr(settings, "supabase_service_role_key", "another-secret")
    text = client.get("/status").text
    assert "another-secret" not in text


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

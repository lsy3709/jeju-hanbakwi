"""주소별 동작. docs/api.md 의 약속을 지키는지 확인합니다."""

from tests.conftest import ALICE, BOB


def test_health_and_meta(client):
    assert client.get("/health").json() == {"status": "ok"}
    meta = client.get("/meta").json()
    assert "바다" in meta["themes"]
    assert meta["areas"] == ["제주시", "서귀포시", "동부", "서부"]
    assert "쇼핑" in meta["categories"]


# ---------------------------------------------------------------- 관광지

def test_spots_default_page(client):
    body = client.get("/spots").json()
    assert body["page"] == 1 and body["size"] == 20
    assert len(body["items"]) == 20
    assert body["total"] == 68
    first = body["items"][0]
    assert set(first) == {"id", "title", "category", "area", "address", "lat", "lng", "image_url", "image_credit", "image_source_url", "overview", "one_liner", "theme_tags", "indoor"}


def test_spots_paging(client):
    last = client.get("/spots", params={"page": 4, "size": 20}).json()
    assert len(last["items"]) == 8
    assert client.get("/spots", params={"page": 5, "size": 20}).json()["items"] == []


def test_spots_filters(client):
    sea = client.get("/spots", params={"theme": "바다", "size": 50}).json()
    assert sea["total"] > 5
    assert all("바다" in s["theme_tags"] for s in sea["items"])

    east_indoor = client.get("/spots", params={"area": "동부", "indoor": "true", "size": 50}).json()
    assert east_indoor["total"] >= 2
    assert all(s["area"] == "동부" and s["indoor"] for s in east_indoor["items"])

    food = client.get("/spots", params={"category": "음식점"}).json()
    assert food["total"] == 5

    found = client.get("/spots", params={"q": "폭포"}).json()
    assert {s["title"] for s in found["items"]} == {"천지연폭포", "정방폭포", "천제연폭포"}


def test_spots_bad_query_is_rejected(client):
    assert client.get("/spots", params={"size": 0}).status_code == 422
    assert client.get("/spots", params={"size": 51}).status_code == 422
    assert client.get("/spots", params={"page": 0}).status_code == 422


def test_spot_detail_and_404(client):
    assert client.get("/spots/1").json()["title"] == "성산일출봉"
    missing = client.get("/spots/9999")
    assert missing.status_code == 404
    assert "detail" in missing.json()


# ---------------------------------------------------------------- 날씨

def test_weather_shape(client):
    body = client.get("/weather").json()
    assert body["rainy_today"] is False
    assert [a["area"] for a in body["areas"]] == ["제주시", "서귀포시"]
    assert len(body["areas"][0]["days"]) == 4


def test_weather_unavailable_is_503(client):
    import main
    from services.weather import WeatherUnavailable

    def broken():
        raise WeatherUnavailable("down")

    main.app.dependency_overrides[main.get_weather_service] = lambda: broken
    assert client.get("/weather").status_code == 503


# ---------------------------------------------------------------- 로그인이 필요한 주소

def test_me_routes_need_login(client):
    for method, url in [
        ("get", "/me"),
        ("get", "/me/favorites"),
        ("post", "/me/favorites"),
        ("delete", "/me/favorites/1"),
        ("get", "/me/trips"),
        ("post", "/me/trips"),
        ("delete", "/me/trips/1"),
    ]:
        response = getattr(client, method)(url)
        assert response.status_code == 401, url


def test_wrong_token_is_401(client):
    # Supabase 설정이 없으면 어떤 토큰도 통과하지 못해야 합니다.
    assert client.get("/me", headers={"Authorization": "Bearer made-up-token"}).status_code == 401
    assert client.get("/me", headers={"Authorization": "made-up-token"}).status_code == 401


def test_me(client, login):
    login(ALICE)
    assert client.get("/me").json() == {"id": ALICE.id, "email": "alice@example.com"}


def test_favorites_flow(client, login):
    login(ALICE)
    assert client.get("/me/favorites").json() == []

    added = client.post("/me/favorites", json={"spot_id": 1})
    assert added.status_code == 201 and added.json() == {"spot_id": 1}
    client.post("/me/favorites", json={"spot_id": 3})
    assert client.post("/me/favorites", json={"spot_id": 1}).status_code == 201  # 두 번 찜해도 괜찮음

    titles = [s["title"] for s in client.get("/me/favorites").json()]
    assert titles == ["만장굴", "성산일출봉"]  # 최근에 찜한 순, 중복 없음

    assert client.delete("/me/favorites/1").status_code == 204
    assert [s["title"] for s in client.get("/me/favorites").json()] == ["만장굴"]


def test_favorite_of_missing_spot_is_404(client, login):
    login(ALICE)
    assert client.post("/me/favorites", json={"spot_id": 9999}).status_code == 404


def test_favorites_are_private(client, login):
    login(ALICE)
    client.post("/me/favorites", json={"spot_id": 1})
    login(BOB)
    assert client.get("/me/favorites").json() == []


ITINERARY = [
    {"day": 1, "date": "2026-12-01", "weather": "맑음", "items": [{"time": "오전", "spot_id": 1, "title": "성산일출봉", "reason": "일출"}]}
]


def test_trips_flow(client, login):
    login(ALICE)
    saved = client.post("/me/trips", json={"title": "부모님과 제주", "itinerary": ITINERARY})
    assert saved.status_code == 201
    trip = saved.json()
    assert trip["title"] == "부모님과 제주"
    assert trip["itinerary"][0]["items"][0]["spot_id"] == 1
    assert trip["itinerary"][0]["date"] == "2026-12-01"

    assert [t["id"] for t in client.get("/me/trips").json()] == [trip["id"]]
    assert client.delete(f"/me/trips/{trip['id']}").status_code == 204
    assert client.get("/me/trips").json() == []


def test_trip_validation(client, login):
    login(ALICE)
    assert client.post("/me/trips", json={"title": "", "itinerary": ITINERARY}).status_code == 422
    assert client.post("/me/trips", json={"title": "제목", "itinerary": []}).status_code == 422
    bad_time = [{"day": 1, "items": [{"time": "새벽", "spot_id": 1, "title": "x"}]}]
    assert client.post("/me/trips", json={"title": "제목", "itinerary": bad_time}).status_code == 422


def test_cannot_see_or_delete_other_users_trip(client, login):
    login(ALICE)
    trip_id = client.post("/me/trips", json={"title": "앨리스 일정", "itinerary": ITINERARY}).json()["id"]

    login(BOB)
    assert client.get("/me/trips").json() == []
    assert client.delete(f"/me/trips/{trip_id}").status_code == 404

    login(ALICE)
    assert len(client.get("/me/trips").json()) == 1  # 지워지지 않았음


# ---------------------------------------------------------------- 사진 주소

def test_our_photos_get_full_address(client):
    """DB 에는 "/photos/S001.jpg" 처럼 짧게 들어 있고, 응답에서는 서버 주소를 붙여 줍니다.
    그래야 웹(localhost)과 에뮬레이터(10.0.2.2)가 각자 자기가 부른 서버에서 사진을 받습니다."""
    first = client.get("/spots", params={"size": 1}).json()["items"][0]
    assert first["image_url"] == "http://testserver/photos/S001.jpg"
    assert client.get("/spots/1").json()["image_url"] == "http://testserver/photos/S001.jpg"


def test_outside_photo_and_no_photo_are_left_alone(client, repo):
    repo.spots[0]["image_url"] = "https://example.com/a.jpg"
    repo.spots[1]["image_url"] = None
    items = client.get("/spots", params={"size": 2}).json()["items"]
    assert items[0]["image_url"] == "https://example.com/a.jpg"
    assert items[1]["image_url"] is None


def test_photo_address_in_favorites_and_plan(client, login):
    login(ALICE)
    client.post("/me/favorites", json={"spot_id": 1})
    assert client.get("/me/favorites").json()[0]["image_url"].startswith("http://testserver/photos/")
    plan = client.post("/agent/plan", json={"message": "성산일출봉을 포함한 일정", "days": 1}).json()
    with_photo = [s for s in plan["sources"] if s["image_url"]]
    assert with_photo and all(s["image_url"].startswith("http") for s in with_photo)


def test_public_api_url_setting_wins(client, monkeypatch):
    """배포 환경에서 주소가 http 로 잘못 잡힐 때를 대비해, 설정 값이 있으면 그것을 씁니다."""
    from config import settings

    monkeypatch.setattr(settings, "public_api_url", "https://api.example.com")
    assert client.get("/spots/1").json()["image_url"] == "https://api.example.com/photos/S001.jpg"


def test_photo_file_is_served(client):
    response = client.get("/photos/S001.jpg")
    assert response.status_code == 200
    assert response.headers["content-type"] == "image/jpeg"
    assert client.get("/photos/none.jpg").status_code == 404


def test_repo_data_is_not_changed_by_response(client, repo):
    client.get("/spots/1")
    assert repo.spots[0]["image_url"] == "/photos/S001.jpg"

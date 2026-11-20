"""주소별 동작. docs/api.md 의 약속을 지키는지 확인합니다."""


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
    assert len(body["items"]) == 12
    assert body["total"] == 12
    first = body["items"][0]
    assert set(first) == {"id", "title", "category", "area", "address", "lat", "lng", "image_url", "image_credit", "image_source_url", "overview", "one_liner", "theme_tags", "indoor"}


def test_spots_paging(client):
    last = client.get("/spots", params={"page": 3, "size": 5}).json()
    assert [s["id"] for s in last["items"]] == [11, 12]
    assert last["total"] == 12
    assert client.get("/spots", params={"page": 4, "size": 5}).json()["items"] == []


def test_spots_bad_query_is_rejected(client):
    assert client.get("/spots", params={"size": 0}).status_code == 422
    assert client.get("/spots", params={"size": 51}).status_code == 422
    assert client.get("/spots", params={"page": 0}).status_code == 422


def test_spot_detail_and_404(client):
    assert client.get("/spots/1").json()["title"] == "성산일출봉"
    missing = client.get("/spots/9999")
    assert missing.status_code == 404
    assert "detail" in missing.json()

"""커서 페이징(찜 · 일정)과 관리자 주소, 이용 정지."""

from services.paging import cut_page
from tests.conftest import ADMIN, ALICE, BOB
from tests.test_api import ITINERARY, walk


# ---------------------------------------------------------------- 커서 계산

def test_cut_page():
    number = lambda row: row["id"]  # noqa: E731
    rows = [{"id": i} for i in (9, 8, 7)]
    assert cut_page(rows, 3, number) == (rows, None)              # 하나 더 오지 않았으면 끝
    assert cut_page(rows, 2, number) == (rows[:2], 8)             # 하나 더 왔으면 마지막 번호가 커서
    assert cut_page([], 20, number) == ([], None)


# ---------------------------------------------------------------- 찜 · 일정 목록

def test_favorites_cursor(client, login):
    login(ALICE)
    for spot_id in range(1, 8):
        client.post("/me/favorites", json={"spot_id": spot_id})

    pages = walk(client, "/me/favorites", size=3)
    assert [len(p["items"]) for p in pages] == [3, 3, 1]
    assert [s["id"] for p in pages for s in p["items"]] == [7, 6, 5, 4, 3, 2, 1]   # 최근에 찜한 순


def test_favorites_cursor_is_stable_when_a_new_one_is_added(client, login):
    """첫 묶음을 받은 뒤 새로 찜해도, 다음 묶음에서 같은 곳이 또 나오지 않습니다."""
    login(ALICE)
    for spot_id in range(1, 6):
        client.post("/me/favorites", json={"spot_id": spot_id})
    first = client.get("/me/favorites", params={"size": 2}).json()
    client.post("/me/favorites", json={"spot_id": 10})
    second = client.get("/me/favorites", params={"size": 2, "cursor": first["next_cursor"]}).json()
    assert [s["id"] for s in first["items"]] == [5, 4]
    assert [s["id"] for s in second["items"]] == [3, 2]


def test_has_favorite_answers_for_one_spot(client, login):
    """찜이 많아 목록의 첫 묶음에 없어도, 한 곳을 찜했는지는 바로 알 수 있어야 합니다."""
    login(ALICE)
    for spot_id in range(1, 31):
        client.post("/me/favorites", json={"spot_id": spot_id})
    first_page = [s["id"] for s in client.get("/me/favorites").json()["items"]]
    assert 1 not in first_page                                   # 가장 먼저 찜한 곳은 첫 묶음에 없음
    assert client.get("/me/favorites/1").json() == {"spot_id": 1, "favorite": True}
    assert client.get("/me/favorites/40").json() == {"spot_id": 40, "favorite": False}
    login(BOB)
    assert client.get("/me/favorites/1").json()["favorite"] is False   # 남의 찜은 내 찜이 아님


def test_trips_cursor(client, login):
    login(ALICE)
    for n in range(5):
        client.post("/me/trips", json={"title": f"일정 {n}", "itinerary": ITINERARY})
    pages = walk(client, "/me/trips", size=2)
    assert [[t["title"] for t in p["items"]] for p in pages] == [["일정 4", "일정 3"], ["일정 2", "일정 1"], ["일정 0"]]


def test_list_size_limits(client, login):
    login(ALICE)
    for url in ("/me/favorites", "/me/trips"):
        assert client.get(url, params={"size": 0}).status_code == 422
        assert client.get(url, params={"size": 51}).status_code == 422


# ---------------------------------------------------------------- 이용 정지

def test_suspended_user_cannot_use_favorites_or_trips(client, login, repo):
    repo.add_profile(ALICE.id, ALICE.email)["suspended"] = True
    login(ALICE)
    me = client.get("/me").json()
    assert me["suspended"] is True                                  # 내 정보는 보임(화면이 안내를 띄울 수 있게)
    for response in (
        client.get("/me/favorites"),
        client.post("/me/favorites", json={"spot_id": 1}),
        client.get("/me/trips"),
        client.post("/me/trips", json={"title": "제목", "itinerary": ITINERARY}),
    ):
        assert response.status_code == 403
    assert repo.favorites == [] and repo.trips == []
    assert client.get("/spots").status_code == 200                  # 누구나 보는 주소는 그대로


# ---------------------------------------------------------------- 관리자: 문지기

ADMIN_ROUTES = [
    ("get", "/admin/users", None),
    ("patch", f"/admin/users/{BOB.id}", {"suspended": True}),
    ("get", "/admin/spots", None),
    ("post", "/admin/spots", {"title": "새 곳", "category": "관광지", "area": "동부"}),
    ("patch", "/admin/spots/1", {"hidden": True}),
]


def test_admin_routes_need_login(client):
    for method, url, body in ADMIN_ROUTES:
        assert client.request(method, url, json=body).status_code == 401, url


def test_admin_routes_refuse_ordinary_user(client, login, repo):
    repo.add_profile(BOB.id, BOB.email)
    login(ALICE)
    for method, url, body in ADMIN_ROUTES:
        assert client.request(method, url, json=body).status_code == 403, url
    assert repo.spots[0]["hidden"] is False and repo.is_suspended(BOB.id) is False
    assert len(repo.spots) == 68


def test_me_tells_admin(client, login):
    login(ADMIN)
    assert client.get("/me").json()["is_admin"] is True


def test_admin_email_compare_ignores_case(client, login):
    from schemas import User

    login(User(id=ADMIN.id, email="Admin@Example.com"))
    assert client.get("/admin/users").status_code == 200


# ---------------------------------------------------------------- 관리자: 사용자

def test_admin_users_list_with_counts_and_cursor(client, login, repo):
    for n in range(5):
        repo.add_profile(f"00000000-0000-0000-0000-0000000000{n:02d}", f"user{n}@example.com")
    repo.add_profile(ALICE.id, ALICE.email)
    login(ALICE)
    client.post("/me/favorites", json={"spot_id": 1})
    client.post("/me/favorites", json={"spot_id": 2})
    client.post("/me/trips", json={"title": "제목", "itinerary": ITINERARY})

    login(ADMIN)
    pages = walk(client, "/admin/users", size=4)
    assert [len(p["items"]) for p in pages] == [4, 2]
    newest = pages[0]["items"][0]
    assert newest["email"] == "alice@example.com"                   # 최근에 가입한 순
    assert (newest["favorite_count"], newest["trip_count"]) == (2, 1)

    found = client.get("/admin/users", params={"q": "user3"}).json()["items"]
    assert [u["email"] for u in found] == ["user3@example.com"]


def test_admin_suspend_and_release(client, login, repo):
    repo.add_profile(BOB.id, BOB.email)
    login(ADMIN)
    assert client.patch(f"/admin/users/{BOB.id}", json={"suspended": True}).json()["suspended"] is True

    login(BOB)
    assert client.post("/me/favorites", json={"spot_id": 1}).status_code == 403

    login(ADMIN)
    assert client.patch(f"/admin/users/{BOB.id}", json={"suspended": False}).json()["suspended"] is False
    login(BOB)
    assert client.post("/me/favorites", json={"spot_id": 1}).status_code == 201


def test_admin_cannot_suspend_self_and_unknown_user_is_404(client, login, repo):
    repo.add_profile(ADMIN.id, ADMIN.email)
    login(ADMIN)
    assert client.patch(f"/admin/users/{ADMIN.id}", json={"suspended": True}).status_code == 400
    assert client.patch(f"/admin/users/{ALICE.id}", json={"suspended": True}).status_code == 404
    assert client.patch("/admin/users/not-a-uuid", json={"suspended": True}).status_code == 422


# ---------------------------------------------------------------- 관리자: 여행지

def test_admin_hides_and_shows_spot(client, login, repo):
    login(ADMIN)
    assert client.patch("/admin/spots/1", json={"hidden": True}).json()["hidden"] is True

    assert client.get("/spots/1").status_code == 404                # 일반 화면에서는 사라짐
    assert client.get("/spots").json()["total"] == 67
    assert client.get("/admin/spots").json()["total"] == 68         # 관리자 목록에는 남음
    only_hidden = client.get("/admin/spots", params={"hidden": "true"}).json()
    assert [s["id"] for s in only_hidden["items"]] == [1]

    client.patch("/admin/spots/1", json={"hidden": False})
    assert client.get("/spots/1").status_code == 200


def test_hidden_spot_leaves_favorites_and_plans(client, login, repo):
    login(ALICE)
    client.post("/me/favorites", json={"spot_id": 1})
    client.post("/me/favorites", json={"spot_id": 2})
    repo.spots[0]["hidden"] = True
    assert [s["id"] for s in client.get("/me/favorites").json()["items"]] == [2]
    plan = client.post("/agent/plan", json={"message": "성산일출봉을 포함한 일정", "days": 1}).json()
    assert all(item["spot_id"] != 1 for day in plan["itinerary"] for item in day["items"])


def test_admin_adds_and_edits_spot(client, login):
    login(ADMIN)
    created = client.post(
        "/admin/spots",
        json={"title": "새로 생긴 전망대", "category": "관광지", "area": "서부", "theme_tags": ["바다", "사진"], "one_liner": "노을이 좋은 곳"},
    )
    assert created.status_code == 201
    spot = created.json()
    assert spot["source"] == "admin" and spot["hidden"] is False

    assert client.get(f"/spots/{spot['id']}").json()["title"] == "새로 생긴 전망대"
    assert client.get("/spots", params={"q": "전망대"}).json()["total"] == 1

    edited = client.patch(f"/admin/spots/{spot['id']}", json={"title": "노을 전망대", "indoor": True}).json()
    assert (edited["title"], edited["indoor"], edited["one_liner"]) == ("노을 전망대", True, "노을이 좋은 곳")


def test_admin_spot_validation(client, login):
    login(ADMIN)
    base = {"title": "이름", "category": "관광지", "area": "동부"}
    assert client.post("/admin/spots", json={**base, "category": "우주선"}).status_code == 422
    assert client.post("/admin/spots", json={**base, "area": "서울"}).status_code == 422
    assert client.post("/admin/spots", json={**base, "theme_tags": ["없는테마"]}).status_code == 422
    assert client.post("/admin/spots", json={**base, "title": ""}).status_code == 422
    assert client.post("/admin/spots", json={**base, "image_url": "javascript:alert(1)"}).status_code == 422
    assert client.post("/admin/spots", json={**base, "lat": 37.5}).status_code == 422       # 제주 밖
    assert client.patch("/admin/spots/1", json={}).status_code == 400
    assert client.patch("/admin/spots/1", json={"title": None}).status_code == 422
    assert client.patch("/admin/spots/9999", json={"hidden": True}).status_code == 404
    # 화면이 보낸 번호나 출처로는 못 바꿈(모르는 칸은 무시)
    assert client.patch("/admin/spots/1", json={"id": 5, "source": "x", "hidden": True}).json()["id"] == 1


def test_admin_changes_spot_photo(client, login):
    """같은 사진을 쓰던 곳을 한 곳씩 다른 사진으로 바꿀 수 있어야 합니다(사진 · 출처를 함께)."""
    login(ADMIN)
    photo = {
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/a/ab/Example.jpg",
        "image_credit": "누군가 · CC BY-SA 4.0 · Wikimedia Commons",
        "image_source_url": "https://commons.wikimedia.org/wiki/File:Example.jpg",
    }
    edited = client.patch("/admin/spots/1", json=photo).json()
    assert {key: edited[key] for key in photo} == photo
    assert client.get("/spots/1").json()["image_credit"] == photo["image_credit"]   # 보는 쪽에도 바로 반영

    # 서버 사진 폴더 안의 파일은 이 서버 주소를 붙여 돌려줍니다
    local = client.patch("/admin/spots/1", json={"image_url": "/photos/S500.jpg"}).json()
    assert local["image_url"].endswith("/photos/S500.jpg") and local["image_url"].startswith("http")

    # 새로 넣을 때도 출처를 함께 적을 수 있습니다
    created = client.post("/admin/spots", json={"title": "사진 있는 곳", "category": "관광지", "area": "동부", **photo}).json()
    assert created["image_source_url"] == photo["image_source_url"]


def test_admin_rejects_bad_photo_address(client, login):
    login(ADMIN)
    for bad in ["javascript:alert(1)", "http://example.com/a.jpg", "/photos/../.env", "/etc/passwd", "/photos/a.exe", "https://"]:
        assert client.patch("/admin/spots/1", json={"image_url": bad}).status_code == 422, bad
    assert client.patch("/admin/spots/1", json={"image_source_url": "javascript:alert(1)"}).status_code == 422
    assert client.patch("/admin/spots/1", json={"image_credit": "가" * 201}).status_code == 422
    assert client.patch("/admin/spots/1", json={"image_url": None}).status_code == 422   # 빈 값으로 지우기는 막음(기존 규칙)


def test_admin_can_clear_photo_credit_when_replacing_the_photo(client, login):
    """사진을 바꾸면서 출처를 비워 보내면("") 옛 사진의 출처가 지워집니다(남의 이름이 새 사진에 붙지 않게)."""
    login(ADMIN)
    client.patch("/admin/spots/1", json={"image_url": "https://x.kr/old.jpg", "image_credit": "옛 사람 · CC0",
                                         "image_source_url": "https://x.kr/old-page"})
    changed = client.patch("/admin/spots/1", json={"image_url": "https://x.kr/new.jpg", "image_credit": "", "image_source_url": ""})
    assert changed.status_code == 200
    body = changed.json()
    assert body["image_url"] == "https://x.kr/new.jpg" and body["image_credit"] is None and body["image_source_url"] is None

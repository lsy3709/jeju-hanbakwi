"""편의 시설(숙소 · 게스트하우스 · 병원 · 약국 · 편의점 · 교통) — 가공과 목록 규칙."""

from constants import CATEGORIES, PLACE_CATEGORIES
from tests.fakes import FakeRepo
from tools.sync_spots import load_places, to_place_rows
from transform import PLACE_PHOTOS, area_by_position, to_place_row

RAW = {"id": "n123", "title": "한라약국", "category": "약국", "area": "제주시", "address": "제주시 중앙로 1",
       "lat": 33.5, "lng": 126.53, "phone": "064-000-0000"}


def test_area_by_position():
    assert area_by_position(33.50, 126.53) == "제주시"     # 제주 시내
    assert area_by_position(33.25, 126.56) == "서귀포시"   # 서귀포 시내
    assert area_by_position(33.46, 126.93) == "동부"       # 성산
    assert area_by_position(33.39, 126.24) == "서부"       # 한림


def test_to_place_row_fills_what_screens_need():
    row = to_place_row(RAW)
    assert row["source"] == "osm" and row["source_id"] == "n123"
    assert row["title"] == "한라약국" and row["category"] == "약국" and row["area"] == "제주시"
    assert (row["lat"], row["lng"]) == (33.5, 126.53)
    assert row["indoor"] is True and row["theme_tags"] == []
    assert "약국" in row["one_liner"] and "제주시" in row["one_liner"]
    assert "064-000-0000" in row["overview"]              # 전화번호는 소개 글에
    # 사진은 분류별 대표 사진 — 우리 서버가 내주는 주소(/photos/…)와 출처가 함께
    assert row["image_url"] == "/photos/" + PLACE_PHOTOS["약국"]["file"]
    assert row["image_credit"] and row["image_source_url"].startswith("https://commons.wikimedia.org/")


def test_to_place_row_rejects_unknown_category_or_missing_position():
    assert to_place_row({**RAW, "category": "주유소"}) is None
    assert to_place_row({**RAW, "lat": None}) is None
    assert to_place_row({**RAW, "title": " "}) is None


def test_every_place_category_has_a_photo():
    assert set(PLACE_PHOTOS) == set(PLACE_CATEGORIES)
    assert not set(PLACE_CATEGORIES) & set(CATEGORIES)     # 여행지 분류와 겹치지 않음


def test_sample_places_file_converts_cleanly():
    raw = load_places()
    rows = to_place_rows(raw)
    assert len(rows) == len(raw) >= 100                    # 빠지는 줄 없이 100곳 이상
    assert {row["category"] for row in rows} == set(PLACE_CATEGORIES)
    assert len({(row["source"], row["source_id"]) for row in rows}) == len(rows)   # 같은 곳이 두 번 없음
    for row in rows:
        assert 33.0 < row["lat"] < 33.7 and 126.0 < row["lng"] < 127.1             # 제주 안


def _repo_with_places():
    repo = FakeRepo()
    repo.upsert_spots(to_place_rows([RAW, {**RAW, "id": "n124", "title": "제주게스트하우스", "category": "게스트하우스"}]))
    return repo


def test_places_are_hidden_from_the_default_list():
    """분류를 고르지 않은 목록(홈 추천 · 탐색 · AI 일정의 후보)에는 편의 시설이 섞이지 않는다."""
    repo = _repo_with_places()
    items, total = repo.list_spots(size=50)
    assert total == 68 and all(item["category"] in CATEGORIES for item in items)


def test_places_show_when_the_category_is_chosen():
    repo = _repo_with_places()
    items, total = repo.list_spots(category="약국")
    assert total == 1 and items[0]["title"] == "한라약국"


def test_meta_lists_place_categories(client):
    meta = client.get("/meta").json()
    assert meta["place_categories"] == PLACE_CATEGORIES
    assert meta["categories"] == CATEGORIES               # 여행지 분류는 그대로


def test_spots_api_serves_places_by_category(client, repo):
    repo.upsert_spots(to_place_rows([RAW]))
    assert client.get("/spots").json()["total"] == 68
    body = client.get("/spots", params={"category": "약국"}).json()
    assert body["total"] == 1 and body["items"][0]["image_url"].endswith("/photos/places/pharmacy.jpg")


def test_to_place_row_uses_the_photo_given_with_the_place():
    """편의 시설도 곳마다 사진을 줄 수 있습니다. 바깥 사진 주소(url)면 그대로 쓰고, 안내 글은 식당 문구가 아니어야 합니다."""
    photo = {"url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/X.jpg/960px-X.jpg",
             "credit": "누군가 · CC0 · Wikimedia Commons", "source_url": "https://commons.wikimedia.org/wiki/File:X.jpg"}
    row = to_place_row({"id": "n1", "title": "어느약국", "category": "약국", "lat": 33.5, "lng": 126.5, "photo": photo})
    assert row["image_url"] == photo["url"]
    assert row["image_credit"] == photo["credit"] and row["image_source_url"] == photo["source_url"]
    assert "예시 사진" in row["overview"] and "식당" not in row["overview"] and "음식" not in row["overview"]


def test_every_sample_place_has_its_own_photo():
    """sample_places.json 의 120곳은 사진 주소가 모두 달라야 하고, 출처가 있어야 합니다."""
    import json
    from pathlib import Path
    places = json.loads((Path(__file__).parent.parent / "data" / "sample_places.json").read_text(encoding="utf-8"))
    rows = [to_place_row(place) for place in places]
    assert len({row["image_url"] for row in rows}) == len(rows) == 120
    assert all(row["image_credit"] and row["image_source_url"].startswith("https://commons.wikimedia.org/wiki/File:") for row in rows)

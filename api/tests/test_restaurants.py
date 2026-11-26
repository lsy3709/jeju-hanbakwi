"""추천 식당(한식 · 해산물 · 고기구이 · 국수 · 카페) — 분류, 중복 없는 데이터, 근처 추천."""

from constants import CATEGORIES, FOOD_CATEGORIES, PLACE_CATEGORIES
from services.nearby import distance_km, nearest
from tests.fakes import FakeRepo
from tools.make_sample_restaurants import drop_duplicates, food_category
from tools.sync_spots import load_places, load_restaurants, load_sample, to_place_rows
from transform import FOOD_PHOTOS, to_place_row

RAW = {"id": "n900", "title": "올래국수", "category": "국수", "area": "제주시", "address": "제주시 귀아랑길 24",
       "lat": 33.49, "lng": 126.49, "phone": ""}


# ---------- 분류 ----------
def test_food_categories_do_not_overlap_other_categories():
    assert len(FOOD_CATEGORIES) == 5
    assert not set(FOOD_CATEGORIES) & set(CATEGORIES)
    assert not set(FOOD_CATEGORIES) & set(PLACE_CATEGORIES)
    assert set(FOOD_PHOTOS) == set(FOOD_CATEGORIES)      # 분류마다 대표 사진


def test_food_category_from_map_tags_and_name():
    assert food_category({"amenity": "cafe"}, "바다보는카페") == "카페"
    assert food_category({"amenity": "restaurant", "cuisine": "seafood"}, "용두암집") == "해산물"
    assert food_category({"amenity": "restaurant"}, "성산해녀횟집") == "해산물"
    assert food_category({"amenity": "restaurant"}, "돈사돈 흑돼지") == "고기구이"
    assert food_category({"amenity": "restaurant", "cuisine": "noodle"}, "자매집") == "국수"
    assert food_category({"amenity": "restaurant"}, "올래국수") == "국수"
    assert food_category({"amenity": "restaurant", "cuisine": "korean"}, "한라가든") == "한식"
    assert food_category({"amenity": "restaurant"}, "은희네해장국") == "한식"
    assert food_category({"amenity": "restaurant", "cuisine": "pizza"}, "피자집") is None     # 다섯 분류 밖은 쓰지 않음
    assert food_category({"amenity": "restaurant"}, "이름만있는집") is None


# ---------- 가공 ----------
def test_to_place_row_makes_a_restaurant_row():
    row = to_place_row(RAW)
    assert row["category"] == "국수" and row["title"] == "올래국수" and row["source"] == "osm"
    assert row["image_url"] == "/photos/" + FOOD_PHOTOS["국수"]["file"]
    assert row["image_source_url"].startswith("https://commons.wikimedia.org/")
    assert "국수" in row["one_liner"] and row["indoor"] is True


# ---------- 중복 ----------
def test_drop_duplicates_by_id_and_by_name():
    items = [
        {"id": "n1", "title": "올래국수"},
        {"id": "n1", "title": "올래국수 본점"},      # 같은 번호
        {"id": "n2", "title": "올래 국수"},          # 띄어쓰기만 다른 같은 이름
        {"id": "n3", "title": "동문시장"},           # 이미 있는 여행지와 같은 이름
        {"id": "n4", "title": "자매국수"},
    ]
    kept = drop_duplicates(items, taken_titles={"동문시장"})
    assert [item["id"] for item in kept] == ["n1", "n4"]


def test_sample_restaurants_have_no_duplicates():
    foods = load_restaurants()
    assert 95 <= len(foods) <= 105                                   # 100곳 안팎
    assert {food["category"] for food in foods} == set(FOOD_CATEGORIES)
    for name in FOOD_CATEGORIES:
        assert sum(1 for food in foods if food["category"] == name) >= 15

    def norm(title):
        return title.replace(" ", "")

    ids = [food["id"] for food in foods]
    titles = [norm(food["title"]) for food in foods]
    assert len(set(ids)) == len(ids)                                 # 번호가 겹치지 않음
    assert len(set(titles)) == len(titles)                           # 이름이 겹치지 않음
    others = {norm(place["title"]) for place in load_places()} | {norm(spot["title"]) for spot in load_sample()}
    assert not set(titles) & others                                  # 여행지 · 편의 시설과도 겹치지 않음
    assert not set(ids) & {place["id"] for place in load_places()}
    for food in foods:
        assert 33.1 <= food["lat"] <= 33.62 and 126.08 <= food["lng"] <= 127.02   # 제주 안
    assert len(to_place_rows(foods)) == len(foods)                   # 모두 DB 한 줄로 바뀜


# ---------- 목록 규칙 ----------
def repo_with_foods():
    repo = FakeRepo()
    repo.upsert_spots(to_place_rows(load_restaurants()))
    return repo


def test_restaurants_stay_out_of_the_default_list():
    repo = repo_with_foods()
    items, total = repo.list_spots(size=500)
    assert total == 68                                               # 샘플 여행지 수 그대로
    assert not [item for item in items if item["category"] in FOOD_CATEGORIES]


def test_restaurants_show_when_the_category_is_chosen():
    repo = repo_with_foods()
    items, total = repo.list_spots(category="국수", size=50)
    assert total >= 15 and all(item["category"] == "국수" for item in items)


def test_meta_lists_food_categories(client):
    assert client.get("/meta").json()["food_categories"] == FOOD_CATEGORIES


# ---------- 근처 추천 ----------
def test_distance_km():
    assert distance_km(33.5, 126.5, 33.5, 126.5) == 0
    # 제주시청 ~ 서귀포시청 은 직선으로 약 30km
    assert 27 < distance_km(33.4996, 126.5312, 33.2541, 126.5600) < 30


def test_nearest_sorts_by_distance_and_skips_what_has_no_position():
    here = {"id": 1, "lat": 33.50, "lng": 126.50}
    candidates = [
        {"id": 10, "title": "먼 집", "lat": 33.30, "lng": 126.50},
        {"id": 11, "title": "가까운 집", "lat": 33.501, "lng": 126.501},
        {"id": 12, "title": "좌표 없는 집", "lat": None, "lng": None},
        {"id": 13, "title": "중간 집", "lat": 33.52, "lng": 126.50},
        {"id": 1, "title": "나 자신", "lat": 33.50, "lng": 126.50},
    ]
    found = nearest(here, candidates, size=2)
    assert [item["title"] for item in found] == ["가까운 집", "중간 집"]
    assert found[0]["distance_km"] < 0.3 and found[1]["distance_km"] > 2


def test_nearby_restaurants_address(client, repo):
    repo.upsert_spots(to_place_rows(load_restaurants()))
    spot = repo.list_spots(size=1)[0][0]
    found = client.get(f"/spots/{spot['id']}/restaurants?size=3").json()
    assert len(found) == 3
    assert all(item["category"] in FOOD_CATEGORIES for item in found)
    assert [item["distance_km"] for item in found] == sorted(item["distance_km"] for item in found)
    assert found[0]["image_url"].startswith("http")                  # 사진 주소가 완성된 주소로
    assert client.get("/spots/99999999/restaurants").status_code == 404


def test_nearby_restaurants_is_empty_before_data_is_loaded(client, repo):
    spot = repo.list_spots(size=1)[0][0]
    assert client.get(f"/spots/{spot['id']}/restaurants").json() == []

"""예시 데이터 도구(tools/seed_demo.py)가 서버의 응답 모양과 맞는지 확인합니다.

찜·일정 목록은 {"items": [...], "next_cursor": ...} 로 한 묶음씩 옵니다.
도구가 이 모양을 따라 끝까지 읽는지(20개가 넘어도) 봅니다.
"""

from tests.conftest import ALICE
from tests.test_api import ITINERARY
from tools import seed_demo


def test_seed_adds_favorites_and_trips_once(client, login, capsys):
    login(ALICE)
    seed_demo.seed(client)
    seed_demo.seed(client)  # 두 번 실행해도 같은 것이 또 생기지 않아야 합니다

    favorites = client.get("/me/favorites").json()["items"]
    trips = client.get("/me/trips").json()["items"]
    assert "성산일출봉" in [spot["title"] for spot in favorites]
    assert len(favorites) == len({spot["id"] for spot in favorites})
    titles = [trip["title"] for trip in trips]
    assert titles and len(titles) == len(set(titles))
    assert "이미 있어 건너뜁니다" in capsys.readouterr().out


def test_clear_removes_everything_even_past_one_page(client, login, capsys):
    login(ALICE)
    client.post("/me/favorites", json={"spot_id": 1})
    client.post("/me/favorites", json={"spot_id": 3})
    for number in range(25):  # 한 묶음(20개)을 넘깁니다
        client.post("/me/trips", json={"title": f"일정 {number}", "itinerary": ITINERARY})

    seed_demo.clear(client)

    assert client.get("/me/favorites").json() == {"items": [], "next_cursor": None}
    assert client.get("/me/trips").json() == {"items": [], "next_cursor": None}
    assert "찜 2개, 일정 25개를 지웠습니다." in capsys.readouterr().out

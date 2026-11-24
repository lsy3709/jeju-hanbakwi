"""예시 데이터 넣기: 로그인한 내 계정에 찜 몇 개와 저장한 일정 두 개를 만들어 줍니다.

"내 여행" 화면이 비어 있으면 화면을 만들거나 시연하기 어렵기 때문에 쓰는 도구입니다.
서버의 주소(API)를 통해서만 넣습니다. DB 를 직접 건드리지 않습니다.

api 폴더에서 실행합니다. (서버가 켜져 있고, 관광지 데이터가 들어 있어야 합니다)

  python -m tools.seed_demo --token local-dev-token      로컬 Docker DB 일 때
  python -m tools.seed_demo --token <액세스 토큰>         진짜 Supabase 일 때
  python -m tools.seed_demo --token ... --clear          내 찜과 일정을 모두 지우기
"""

# 이 도구는 DB 를 직접 만지지 않고, 켜져 있는 서버의 주소(/spots, /me/favorites, /me/trips)를 로그인 토큰과 함께 부릅니다.
# 그래서 서버의 로그인 확인·이용 정지 같은 규칙을 그대로 지나갑니다. 일정 제목이 이미 있으면 건너뛰어 여러 번 돌려도 안전합니다.
import argparse
import sys
from datetime import date, timedelta

import httpx

FAVORITE_TITLES = ["성산일출봉", "협재해수욕장", "사려니숲길", "오설록 티뮤지엄", "동문재래시장", "천지연폭포"]

# (일정 제목, 날짜별 [(시간대, 관광지 이름, 이유)])
TRIPS = [
    (
        "부모님과 동쪽 한 바퀴",
        [
            [("오전", "성산일출봉", "제주 동쪽의 대표 풍경을 먼저 봅니다."), ("점심", "세화해변 카페거리", "바다를 보며 쉬어 갑니다."), ("오후", "비자림", "평탄한 숲길이라 부모님과 걷기 좋습니다.")],
            [("오전", "제주민속촌", "옛 제주의 생활 모습을 둘러봅니다."), ("오후", "표선해수욕장", "넓은 모래밭을 가볍게 산책합니다.")],
        ],
    ),
    (
        "비 오는 날 실내 코스",
        [
            [("오전", "국립제주박물관", "비를 피해 제주의 역사를 살펴봅니다."), ("점심", "국수문화거리", "따뜻한 고기국수로 점심을 먹습니다."), ("오후", "넥슨컴퓨터박물관", "직접 해 보는 전시가 많습니다."), ("저녁", "동문재래시장", "지붕 아래에서 야시장 먹거리를 즐깁니다.")],
        ],
    ),
]


def find_spot(client: httpx.Client, title: str) -> dict | None:
    """이름으로 관광지를 찾습니다. 내 DB 에 없는 이름이면 None."""
    items = client.get("/spots", params={"q": title, "size": 10}).json().get("items", [])
    return next((s for s in items if s["title"] == title), None)


def clear(client: httpx.Client) -> None:
    favorites = client.get("/me/favorites").json()
    trips = client.get("/me/trips").json()
    for spot in favorites:
        client.delete(f"/me/favorites/{spot['id']}")
    for trip in trips:
        client.delete(f"/me/trips/{trip['id']}")
    print(f"찜 {len(favorites)}개, 일정 {len(trips)}개를 지웠습니다.")


def seed(client: httpx.Client) -> None:
    added = 0
    for title in FAVORITE_TITLES:
        spot = find_spot(client, title)
        if spot and client.post("/me/favorites", json={"spot_id": spot["id"]}).status_code == 201:
            added += 1
    print(f"찜 {added}개를 넣었습니다.")

    existing = {trip["title"] for trip in client.get("/me/trips").json()}
    start = date.today() + timedelta(days=7)
    for title, days in TRIPS:
        if title in existing:  # 두 번 실행해도 같은 일정이 또 생기지 않게
            print(f"일정 '{title}' 은(는) 이미 있어 건너뜁니다.")
            continue
        itinerary = []
        for index, items in enumerate(days):
            # 이름으로 관광지를 찾아 번호(spot_id)를 알아냅니다. 이 DB 에 없는 이름은 None 이라 아래에서 빠집니다.
            found = [(time, find_spot(client, name), reason) for time, name, reason in items]
            day_items = [
                {"time": time, "spot_id": spot["id"], "title": spot["title"], "reason": reason}
                for time, spot, reason in found
                if spot
            ]
            if day_items:
                itinerary.append({"day": index + 1, "date": str(start + timedelta(days=index)), "weather": None, "items": day_items})
        if not itinerary:
            print(f"일정 '{title}': 내 DB 에 해당 관광지가 없어 만들지 못했습니다.")
            continue
        response = client.post("/me/trips", json={"title": title, "itinerary": itinerary})
        print(f"일정 '{title}': {'넣었습니다' if response.status_code == 201 else f'실패({response.status_code})'}")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="내 계정에 예시 찜·일정 넣기")
    parser.add_argument("--api", default="http://localhost:8000", help="서버 주소")
    parser.add_argument("--token", required=True, help="로그인 토큰 (로컬 Docker DB 는 local-dev-token)")
    parser.add_argument("--clear", action="store_true", help="넣지 않고, 내 찜과 일정을 모두 지웁니다")
    args = parser.parse_args()

    headers = {"Authorization": f"Bearer {args.token}"}
    try:
        with httpx.Client(base_url=args.api.rstrip("/"), headers=headers, timeout=20) as client:
            me = client.get("/me")
            if me.status_code != 200:
                print("로그인 토큰이 올바르지 않습니다.")
                return 1
            print(f"계정: {me.json().get('email')}")
            # --clear 를 줬으면 지우고, 아니면 넣습니다. (한 줄짜리 if/else 식)
            clear(client) if args.clear else seed(client)
    except httpx.ConnectError:
        print(f"서버에 연결할 수 없습니다: {args.api}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

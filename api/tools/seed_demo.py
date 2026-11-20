"""예시 데이터 넣기: 로그인한 내 계정에 찜 몇 개를 만들어 줍니다.

"내 여행" 화면의 찜한 곳이 비어 있으면 화면을 만들거나 시연하기 어렵기 때문에 쓰는 도구입니다.
서버의 주소(API)를 통해서만 넣습니다. DB 를 직접 건드리지 않습니다.

api 폴더에서 실행합니다. (서버가 켜져 있고, 관광지 데이터가 들어 있어야 합니다)

  python -m tools.seed_demo --token local-dev-token      로컬 Docker DB 일 때
  python -m tools.seed_demo --token <액세스 토큰>         진짜 Supabase 일 때
  python -m tools.seed_demo --token ... --clear          내 찜을 모두 지우기
"""

import argparse
import sys

import httpx

FAVORITE_TITLES = ["성산일출봉", "협재해수욕장", "사려니숲길", "오설록 티뮤지엄", "동문재래시장", "천지연폭포"]


def find_spot(client: httpx.Client, title: str) -> dict | None:
    """이름으로 관광지를 찾습니다. 내 DB 에 없는 이름이면 None."""
    items = client.get("/spots", params={"q": title, "size": 10}).json().get("items", [])
    return next((s for s in items if s["title"] == title), None)


def clear(client: httpx.Client) -> None:
    favorites = client.get("/me/favorites").json()
    for spot in favorites:
        client.delete(f"/me/favorites/{spot['id']}")
    print(f"찜 {len(favorites)}개를 지웠습니다.")


def seed(client: httpx.Client) -> None:
    added = 0
    for title in FAVORITE_TITLES:
        spot = find_spot(client, title)
        if spot and client.post("/me/favorites", json={"spot_id": spot["id"]}).status_code == 201:
            added += 1
    print(f"찜 {added}개를 넣었습니다.")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="내 계정에 예시 찜 넣기")
    parser.add_argument("--api", default="http://localhost:8000", help="서버 주소")
    parser.add_argument("--token", required=True, help="로그인 토큰 (로컬 Docker DB 는 local-dev-token)")
    parser.add_argument("--clear", action="store_true", help="넣지 않고, 내 찜을 모두 지웁니다")
    args = parser.parse_args()

    headers = {"Authorization": f"Bearer {args.token}"}
    try:
        with httpx.Client(base_url=args.api.rstrip("/"), headers=headers, timeout=20) as client:
            me = client.get("/me")
            if me.status_code != 200:
                print("로그인 토큰이 올바르지 않습니다.")
                return 1
            print(f"계정: {me.json().get('email')}")
            clear(client) if args.clear else seed(client)
    except httpx.ConnectError:
        print(f"서버에 연결할 수 없습니다: {args.api}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

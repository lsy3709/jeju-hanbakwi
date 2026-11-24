"""실측 점검: 켜져 있는 서버를 실제로 불러 보고, DB 까지 다녀온 결과를 확인합니다.

단위 테스트(pytest)는 가짜 DB 로 "논리"를 보고,
이 도구는 진짜 서버 + 진짜 DB + 진짜 외부 서비스로 "연결"을 봅니다.

api 폴더에서 실행합니다. (서버가 먼저 켜져 있어야 합니다)

  python -m tools.check_live                              로그인 없이 볼 수 있는 것만
  python -m tools.check_live --token local-dev-token      로컬 Docker DB 일 때 (찜·일정까지)
  python -m tools.check_live --token <액세스 토큰>         진짜 Supabase 일 때
  python -m tools.check_live --api https://내서버.vercel.app   배포한 서버 점검
  python -m tools.check_live --skip-ai                    AI 일정은 건너뛰기 (호출 한도 아끼기)

찜·일정 점검은 만든 것을 스스로 지우고 끝납니다.
토큰의 주인이 관리자(서버의 ADMIN_EMAILS)면 관리자 주소도 점검합니다. 숨긴 여행지는 바로 되돌립니다.
"""

# 이 파일은 pytest 테스트가 아닙니다. 진짜로 켜 둔 서버에 요청을 보내고, 기대한 응답(상태 코드·모양)이 오는지 ✅/❌ 로 찍어 줍니다.
# 단위 테스트(tests/)가 가짜 DB 로 "코드의 논리"를 본다면, 이 도구는 배포 직후 "연결이 진짜로 되는지"를 봅니다.
# 단계: [1] 공개 주소 → [2] DB 관광지 → [3] 날씨 → [4] AI 일정 → [5~6] 로그인·찜·일정 → [7] 관리자.
import argparse
import sys
import time

import httpx

results: list[tuple[bool, str]] = []


# 확인 한 가지의 결과를 화면에 찍고 results 에 모아 둡니다. 맨 끝에서 실패한 것만 다시 보여 주기 위해서입니다.
def check(name: str, ok: bool, detail: str = "", ms: float | None = None) -> bool:
    took = f" ({ms:.0f}ms)" if ms is not None else ""
    print(f"  {'✅' if ok else '❌'} {name}{took}{' — ' + detail if detail else ''}")
    results.append((ok, name))
    return ok


def call(client: httpx.Client, method: str, url: str, **kwargs):
    """한 번 부르고 (응답, 걸린 시간 ms) 를 돌려줍니다."""
    started = time.perf_counter()
    response = client.request(method, url, **kwargs)
    return response, (time.perf_counter() - started) * 1000


def walk(client: httpx.Client, url: str, size: int, headers: dict | None = None, **params):
    """next_cursor 를 따라 끝까지 받습니다. → (받은 번호들, 묶음 수)"""
    ids, pages, cursor = [], 0, None
    while pages < 200:  # 혹시 커서가 제자리를 돌아도 멈추게
        query = {**params, "size": size, **({"cursor": cursor} if cursor is not None else {})}
        body = client.get(url, params=query, headers=headers).json()
        ids += [item["id"] for item in body["items"]]
        pages += 1
        cursor = body.get("next_cursor")
        if cursor is None:
            break
    return ids, pages


def check_public(client: httpx.Client) -> None:
    print("\n[1] 누구나 볼 수 있는 주소")
    r, ms = call(client, "GET", "/health")
    check("서버 응답 /health", r.status_code == 200 and r.json() == {"status": "ok"}, ms=ms)

    r, ms = call(client, "GET", "/status")
    state = r.json() if r.status_code == 200 else {}
    check(
        "연결 상태 /status",
        state.get("database") == "ok",
        f"DB {state.get('database')}, 관광지 {state.get('spots')}건, 일정 방식 {state.get('ai')}, 로그인 {state.get('login')}, 사진 {state.get('photos')}장",
        ms,
    )

    r, ms = call(client, "GET", "/meta")
    meta = r.json() if r.status_code == 200 else {}
    check("선택지 /meta", bool(meta.get("themes")) and bool(meta.get("areas")), f"테마 {len(meta.get('themes', []))}개", ms)

    print("\n[2] DB 연동 — 관광지")
    r, ms = call(client, "GET", "/spots", params={"size": 5})
    body = r.json() if r.status_code == 200 else {}
    total = body.get("total", 0)
    items = body.get("items", [])
    if not check("목록이 DB 에서 온다", r.status_code == 200 and total > 0 and len(items) == min(5, total), f"전체 {total}건", ms):
        print("     DB 에 데이터가 없으면: python -m tools.sync_spots --sample")
        return

    # 커서를 따라 끝까지 받아 봅니다. 겹치지도 빠지지도 않고 전체 개수와 맞아야 합니다.
    started = time.perf_counter()
    ids, pages = walk(client, "/spots", size=20)
    ms = (time.perf_counter() - started) * 1000
    check(
        "커서 페이징 (끝까지 받아도 겹치거나 빠지지 않음)",
        len(ids) == len(set(ids)) == total and ids == sorted(ids),
        f"{pages}묶음, {len(ids)}건",
        ms,
    )
    r, ms = call(client, "GET", "/spots", params={"size": 5, "cursor": ids[-1]})
    check("마지막 커서 뒤는 빈 묶음", r.status_code == 200 and r.json()["items"] == [] and r.json()["next_cursor"] is None, ms=ms)

    theme = meta.get("themes", [""])[0]
    r, ms = call(client, "GET", "/spots", params={"theme": theme, "size": 50})
    themed = r.json().get("items", [])
    check(f"테마 필터 '{theme}'", bool(themed) and all(theme in s["theme_tags"] for s in themed), f"{len(themed)}건", ms)

    r, ms = call(client, "GET", "/spots", params={"indoor": "true", "size": 50})
    indoor = r.json().get("items", [])
    check("실내 필터", bool(indoor) and all(s["indoor"] for s in indoor), f"{len(indoor)}건", ms)

    word = items[0]["title"][:2]
    r, ms = call(client, "GET", "/spots", params={"q": word, "size": 50})
    found = r.json().get("items", [])
    check(f"검색 '{word}'", any(s["id"] == items[0]["id"] for s in found), f"{len(found)}건", ms)

    # DB 필터 문법에 쓰이는 기호(, . ))를 섞은 검색어를 보내, repo.clean_search_word 가 기호를 지워 주는지 봅니다.
    r, ms = call(client, "GET", "/spots", params={"q": "a,id.gt.0)"})
    check("검색어로 필터를 조작할 수 없다", r.status_code == 200 and r.json().get("total", 1) < total, ms=ms)

    r, ms = call(client, "GET", f"/spots/{items[0]['id']}")
    check("상세", r.status_code == 200 and r.json()["title"] == items[0]["title"], items[0]["title"], ms)

    r, ms = call(client, "GET", "/spots/999999999")
    check("없는 관광지는 404", r.status_code == 404, ms=ms)

    with_photo = next((s for s in items if s.get("image_url")), None)
    if with_photo:
        # 사진 주소는 완성된 주소(http...)로 와야 하고, 실제로 그림이 받아져야 합니다.
        r = httpx.get(with_photo["image_url"], timeout=20, follow_redirects=True)
        is_image = r.status_code == 200 and r.headers.get("content-type", "").startswith("image/")
        check("사진이 실제로 받아진다", with_photo["image_url"].startswith("http") and is_image, with_photo["image_url"])
        check("사진 출처가 함께 온다", bool(with_photo.get("image_credit")), with_photo.get("image_credit") or "")

    print("\n[3] 외부 서비스 — 날씨")
    r, ms = call(client, "GET", "/weather")
    if r.status_code == 200:
        weather = r.json()
        days = weather["areas"][0]["days"]
        check("날씨 (Open-Meteo)", len(weather["areas"]) == 2 and len(days) == 4, f"{days[0]['date']} {days[0]['label']}", ms)
    else:
        check("날씨 (Open-Meteo)", False, f"응답 {r.status_code}", ms)


def check_plan(client: httpx.Client) -> None:
    print("\n[4] AI 일정")
    r, ms = call(client, "POST", "/agent/plan", json={"message": "비가 와도 괜찮은 하루 코스", "days": 1}, timeout=120)
    if r.status_code != 200:
        check("일정 짜기", False, f"응답 {r.status_code}", ms)
        return
    plan = r.json()
    spot_ids = {item["spot_id"] for day in plan["itinerary"] for item in day["items"]}
    source_ids = {s["id"] for s in plan["sources"]}
    check("일정 짜기", bool(spot_ids), f"방식 {plan['mode']}, 장소 {len(spot_ids)}곳", ms)
    check("일정의 장소가 모두 DB 에 있는 곳", spot_ids <= source_ids)
    if plan["mode"] == "rule":
        print("     (AI 가 아니라 규칙으로 짠 일정입니다. GEMINI_API_KEY 와 서버 로그를 확인하세요)")
    if ms > 25000:
        print("     (25초를 넘었습니다. 배포 환경의 응답 시간 제한에 걸릴 수 있습니다)")


def check_login(client: httpx.Client, token: str | None) -> None:
    print("\n[5] 로그인이 필요한 주소")
    r, ms = call(client, "GET", "/me")
    check("토큰이 없으면 401", r.status_code == 401, ms=ms)
    r, ms = call(client, "GET", "/me", headers={"Authorization": "Bearer not-a-real-token"})
    check("틀린 토큰이면 401", r.status_code == 401, ms=ms)

    if not token:
        print("  (--token 이 없어 찜·일정 저장은 점검하지 않았습니다)")
        return

    auth = {"Authorization": f"Bearer {token}"}
    r, ms = call(client, "GET", "/me", headers=auth)
    me = r.json() if r.status_code == 200 else {}
    if not check("내 정보 /me", bool(me.get("id")), f"{me.get('email', '')}{' (관리자)' if me.get('is_admin') else ''}" if me else f"응답 {r.status_code}", ms):
        return
    if me.get("suspended"):
        print("  (이용 정지된 계정이라 찜·일정 점검을 건너뜁니다)")
        return

    print("\n[6] DB 연동 — 찜과 저장한 일정 (만들고, 확인하고, 지웁니다)")
    spot = client.get("/spots", params={"size": 1}).json()["items"][0]
    before, _ = walk(client, "/me/favorites", size=50, headers=auth)

    r, ms = call(client, "POST", "/me/favorites", json={"spot_id": spot["id"]}, headers=auth)
    check("찜 추가", r.status_code == 201, spot["title"], ms)
    r, ms = call(client, "GET", "/me/favorites", headers=auth)
    body = r.json()
    check("찜 목록에 보인다 (최근에 찜한 것이 맨 앞)", body["items"][0]["id"] == spot["id"] or spot["id"] in before, ms=ms)
    r, ms = call(client, "GET", "/me/favorites", params={"size": 1}, headers=auth)
    more = r.json()
    check("찜 목록 커서", (more["next_cursor"] is None) == (len(before) + (spot["id"] not in before) <= 1), f"next_cursor {more['next_cursor']}", ms)
    r, ms = call(client, "POST", "/me/favorites", json={"spot_id": 999999999}, headers=auth)
    check("없는 관광지는 찜할 수 없다 (404)", r.status_code == 404, ms=ms)
    if spot["id"] not in before:  # 원래 찜해 둔 것이면 지우지 않습니다
        r, ms = call(client, "DELETE", f"/me/favorites/{spot['id']}", headers=auth)
        gone = spot["id"] not in walk(client, "/me/favorites", size=50, headers=auth)[0]
        check("찜 삭제", r.status_code == 204 and gone, ms=ms)

    itinerary = [{"day": 1, "date": None, "weather": None, "items": [{"time": "오전", "spot_id": spot["id"], "title": spot["title"], "reason": "실측 점검"}]}]
    r, ms = call(client, "POST", "/me/trips", json={"title": "실측 점검용 일정", "itinerary": itinerary}, headers=auth)
    if check("일정 저장", r.status_code == 201, ms=ms):
        trip_id = r.json()["id"]
        r, ms = call(client, "GET", "/me/trips", headers=auth)
        saved = next((t for t in r.json()["items"] if t["id"] == trip_id), None)
        check("저장한 일정이 그대로 돌아온다", bool(saved) and saved["itinerary"][0]["items"][0]["spot_id"] == spot["id"], ms=ms)
        r, ms = call(client, "DELETE", f"/me/trips/{trip_id}", headers=auth)
        gone = trip_id not in walk(client, "/me/trips", size=50, headers=auth)[0]
        check("일정 삭제", r.status_code == 204 and gone, ms=ms)
        r, ms = call(client, "DELETE", f"/me/trips/{trip_id}", headers=auth)
        check("이미 지운 일정은 404", r.status_code == 404, ms=ms)

    check_admin(client, auth, is_admin=bool(me.get("is_admin")), spot=spot)


def check_admin(client: httpx.Client, auth: dict, is_admin: bool, spot: dict) -> None:
    print("\n[7] 관리자 주소")
    r, ms = call(client, "GET", "/admin/users")
    check("토큰이 없으면 401", r.status_code == 401, ms=ms)
    r, ms = call(client, "GET", "/admin/users", params={"size": 5}, headers=auth)
    if not is_admin:
        check("관리자가 아니면 403", r.status_code == 403, ms=ms)
        print("  (이 토큰은 관리자가 아니어서 관리자 기능은 점검하지 않았습니다. 서버의 ADMIN_EMAILS 를 확인하세요)")
        return

    users = r.json().get("items", []) if r.status_code == 200 else []
    if not check("사용자 목록", r.status_code == 200 and bool(users), f"{len(users)}명, 찜 {users[0]['favorite_count']}건" if users else f"응답 {r.status_code}", ms):
        print("     profiles 표가 없으면: supabase/migrations/003_admin.sql 을 실행하세요")
        return
    ids, pages = walk(client, "/admin/users", size=2, headers=auth)
    check("사용자 목록 커서", len(ids) == len(set(ids)), f"{pages}묶음, {len(ids)}명")

    me_id = client.get("/me", headers=auth).json()["id"]
    r, ms = call(client, "PATCH", f"/admin/users/{me_id}", json={"suspended": True}, headers=auth)
    check("자기 자신은 정지할 수 없다 (400)", r.status_code == 400, ms=ms)

    # try/finally: 확인 도중 오류가 나도 finally 안의 "되돌리기"는 반드시 실행되어 운영 데이터가 숨겨진 채 남지 않습니다.
    # 숨겼다가 되돌립니다. 숨긴 동안 일반 주소에서는 404 여야 합니다.
    r, ms = call(client, "PATCH", f"/admin/spots/{spot['id']}", json={"hidden": True}, headers=auth)
    hidden_ok = r.status_code == 200 and r.json()["hidden"] is True
    try:
        public = client.get(f"/spots/{spot['id']}").status_code
        in_admin = client.get("/admin/spots", params={"hidden": "true", "size": 50}, headers=auth).json()
        check("여행지 숨김 (일반 화면에서는 404, 관리자 목록에는 남음)", hidden_ok and public == 404 and any(s["id"] == spot["id"] for s in in_admin["items"]), spot["title"], ms)
    finally:
        r, ms = call(client, "PATCH", f"/admin/spots/{spot['id']}", json={"hidden": False}, headers=auth)
    check("여행지 다시 보이기", r.status_code == 200 and client.get(f"/spots/{spot['id']}").status_code == 200, ms=ms)

    r, ms = call(client, "PATCH", f"/admin/spots/{spot['id']}", json={"category": "우주선"}, headers=auth)
    check("정해 둔 분류 밖의 값은 거절 (422)", r.status_code == 422, ms=ms)


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # 윈도우 터미널에서 ✅ 와 한글이 깨지지 않게
    parser = argparse.ArgumentParser(description="켜져 있는 서버 실측 점검")
    parser.add_argument("--api", default="http://localhost:8000", help="서버 주소")
    parser.add_argument("--token", default=None, help="로그인 토큰 (로컬 Docker DB 는 local-dev-token)")
    parser.add_argument("--skip-ai", action="store_true", help="AI 일정 점검을 건너뜁니다")
    args = parser.parse_args()

    print(f"점검 대상: {args.api}")
    try:
        with httpx.Client(base_url=args.api.rstrip("/"), timeout=20) as client:
            check_public(client)
            if not args.skip_ai:
                check_plan(client)
            check_login(client, args.token)
    except httpx.ConnectError:
        print(f"\n❌ 서버에 연결할 수 없습니다: {args.api}\n   서버를 먼저 켜세요:  uvicorn main:app --reload")
        return 1

    failed = [name for ok, name in results if not ok]
    print(f"\n결과: {len(results) - len(failed)}개 통과, {len(failed)}개 실패")
    for name in failed:
        print(f"  - 실패: {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

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
"""

import argparse
import sys
import time

import httpx

results: list[tuple[bool, str]] = []


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

    r2, ms = call(client, "GET", "/spots", params={"size": 5, "page": 2})
    second = r2.json().get("items", [])
    overlap = {s["id"] for s in items} & {s["id"] for s in second}
    check("쪽 나눔 (1쪽과 2쪽이 겹치지 않음)", r2.status_code == 200 and not overlap, ms=ms)

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
    if not check("내 정보 /me", r.status_code == 200 and bool(r.json().get("id")), r.json().get("email", "") if r.status_code == 200 else f"응답 {r.status_code}", ms):
        return

    print("\n[6] DB 연동 — 찜과 저장한 일정 (만들고, 확인하고, 지웁니다)")
    spot = client.get("/spots", params={"size": 1}).json()["items"][0]
    before = {s["id"] for s in client.get("/me/favorites", headers=auth).json()}

    r, ms = call(client, "POST", "/me/favorites", json={"spot_id": spot["id"]}, headers=auth)
    check("찜 추가", r.status_code == 201, spot["title"], ms)
    r, ms = call(client, "GET", "/me/favorites", headers=auth)
    check("찜 목록에 보인다", any(s["id"] == spot["id"] for s in r.json()), ms=ms)
    r, ms = call(client, "POST", "/me/favorites", json={"spot_id": 999999999}, headers=auth)
    check("없는 관광지는 찜할 수 없다 (404)", r.status_code == 404, ms=ms)
    if spot["id"] not in before:  # 원래 찜해 둔 것이면 지우지 않습니다
        r, ms = call(client, "DELETE", f"/me/favorites/{spot['id']}", headers=auth)
        gone = all(s["id"] != spot["id"] for s in client.get("/me/favorites", headers=auth).json())
        check("찜 삭제", r.status_code == 204 and gone, ms=ms)

    itinerary = [{"day": 1, "date": None, "weather": None, "items": [{"time": "오전", "spot_id": spot["id"], "title": spot["title"], "reason": "실측 점검"}]}]
    r, ms = call(client, "POST", "/me/trips", json={"title": "실측 점검용 일정", "itinerary": itinerary}, headers=auth)
    if check("일정 저장", r.status_code == 201, ms=ms):
        trip_id = r.json()["id"]
        r, ms = call(client, "GET", "/me/trips", headers=auth)
        saved = next((t for t in r.json() if t["id"] == trip_id), None)
        check("저장한 일정이 그대로 돌아온다", bool(saved) and saved["itinerary"][0]["items"][0]["spot_id"] == spot["id"], ms=ms)
        r, ms = call(client, "DELETE", f"/me/trips/{trip_id}", headers=auth)
        gone = all(t["id"] != trip_id for t in client.get("/me/trips", headers=auth).json())
        check("일정 삭제", r.status_code == 204 and gone, ms=ms)
        r, ms = call(client, "DELETE", f"/me/trips/{trip_id}", headers=auth)
        check("이미 지운 일정은 404", r.status_code == 404, ms=ms)


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

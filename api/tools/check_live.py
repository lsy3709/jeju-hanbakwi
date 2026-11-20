"""실측 점검: 켜져 있는 서버를 실제로 불러 보고, DB 까지 다녀온 결과를 확인합니다.

단위 테스트(pytest)는 가짜 DB 로 "논리"를 보고,
이 도구는 진짜 서버 + 진짜 DB + 진짜 외부 서비스로 "연결"을 봅니다.

api 폴더에서 실행합니다. (서버가 먼저 켜져 있어야 합니다)

  python -m tools.check_live
  python -m tools.check_live --api https://내서버.vercel.app   배포한 서버 점검
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
        f"DB {state.get('database')}, 관광지 {state.get('spots')}건, 사진 {state.get('photos')}장",
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


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # 윈도우 터미널에서 ✅ 와 한글이 깨지지 않게
    parser = argparse.ArgumentParser(description="켜져 있는 서버 실측 점검")
    parser.add_argument("--api", default="http://localhost:8000", help="서버 주소")
    args = parser.parse_args()

    print(f"점검 대상: {args.api}")
    try:
        with httpx.Client(base_url=args.api.rstrip("/"), timeout=20) as client:
            check_public(client)
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

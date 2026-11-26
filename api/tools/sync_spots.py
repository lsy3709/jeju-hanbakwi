"""관광 데이터를 가져와 우리 기준으로 고친 뒤 DB 에 넣는 도구.

api 폴더에서 실행합니다.

  python -m tools.sync_spots --sample            샘플 68건 넣기 (키 없이 가능)
  python -m tools.sync_spots                     TourAPI 에서 제주 데이터 받아 넣기 (TOUR_API_KEY 필요)
  python -m tools.sync_spots --types 12,14       받을 콘텐츠 유형 고르기
  python -m tools.sync_spots --overview 40       소개 글도 받기 (한 건당 호출 1번 → 하루 한도 주의)
  python -m tools.sync_spots --dry-run           DB 에 넣지 않고 결과만 보기

내 주제로 바꿀 때: --types 로 받을 유형을 고르고, transform.py 의 규칙을 고칩니다.
"""

# 이 파일은 서버 주소(routers)가 아니라 사람이 터미널에서 손으로 돌리는 도구입니다.
# 흐름: TourAPI(또는 샘플 파일)에서 원본을 받아 → transform.to_spot_row 로 우리 모양으로 고쳐 → repo.upsert_spots 로 DB 에 넣습니다.
# 낱말: argparse = 터미널에서 준 옵션(--sample, --dry-run 등)을 읽는 파이썬 기본 도구. 같은 데이터를 여러 번 돌려도 upsert 라 중복되지 않습니다.
import argparse
import json
import sys
from pathlib import Path

import httpx

from config import settings
from transform import CATEGORY_BY_TYPE, to_place_row, to_spot_row

SAMPLE_FILE = Path(__file__).parent.parent / "data" / "sample_spots.json"
PLACES_FILE = Path(__file__).parent.parent / "data" / "sample_places.json"
RESTAURANTS_FILE = Path(__file__).parent.parent / "data" / "sample_restaurants.json"
JEJU_AREA_CODE = "39"  # TourAPI 의 지역 번호: 39 = 제주도


def load_sample() -> list[dict]:
    return json.loads(SAMPLE_FILE.read_text(encoding="utf-8"))


def load_places() -> list[dict]:
    """편의 시설 샘플(숙소 · 게스트하우스 · 병원 · 약국 · 편의점 · 교통). tools/make_sample_places.py 가 만든 파일."""
    return json.loads(PLACES_FILE.read_text(encoding="utf-8"))


def load_restaurants() -> list[dict]:
    """추천 식당 샘플(한식 · 해산물 · 고기구이 · 국수 · 카페). tools/make_sample_restaurants.py 가 만든 파일."""
    return json.loads(RESTAURANTS_FILE.read_text(encoding="utf-8"))


def to_place_rows(raw_items: list[dict]) -> list[dict]:
    return [row for row in (to_place_row(item) for item in raw_items) if row is not None]


def call_tour_api(operation: str, params: dict) -> list[dict]:
    """TourAPI 를 한 번 부르고 item 목록을 돌려줍니다."""
    response = httpx.get(
        f"{settings.tour_api_base}/{operation}",
        params={"serviceKey": settings.tour_api_key, "MobileOS": "ETC", "MobileApp": "jeju-hanbakwi", "_type": "json", **params},
        timeout=20,
    )
    response.raise_for_status()
    try:
        body = response.json()["response"]["body"]
    except (ValueError, KeyError) as error:
        # 키가 틀리면 JSON 이 아니라 오류 문서가 옵니다. 앞부분만 보여 줍니다.
        raise RuntimeError(f"TourAPI 응답을 읽을 수 없습니다: {response.text[:200]}") from error
    # 건수가 하나면 item 이 목록이 아닌 사전 하나로 오기도 해서, 아래에서 항상 목록으로 맞춥니다.
    items = body.get("items") or {}
    if not items:  # 결과가 없으면 items 가 빈 글자("")로 옵니다
        return []
    item = items.get("item", [])
    return item if isinstance(item, list) else [item]


def fetch_tour_list(content_type: str, limit: int) -> list[dict]:
    """제주의 한 유형을 limit 건까지 받습니다. (한 번에 100건씩)"""
    # 쪽 번호를 1씩 올려 가며 limit 건이 찰 때까지, 또는 더 받을 것이 없을 때(items 가 빔)까지 받습니다.
    rows: list[dict] = []
    page = 1
    while len(rows) < limit:
        items = call_tour_api(
            "areaBasedList2",
            {"areaCode": JEJU_AREA_CODE, "contentTypeId": content_type, "numOfRows": 100, "pageNo": page, "arrange": "Q"},
        )
        if not items:
            break
        rows.extend(items)
        page += 1
    return rows[:limit]


def fetch_overview(content_id: str) -> str:
    items = call_tour_api("detailCommon2", {"contentId": content_id})
    return str(items[0].get("overview") or "") if items else ""


def to_rows(raw_items: list[dict], source: str) -> tuple[list[dict], int]:
    """원본 목록 → DB 에 넣을 줄. 좌표가 없는 곳은 빼고, 몇 건을 뺐는지 함께 돌려줍니다.

    좌표가 없으면 지도에 찍을 수 없고, 화면(웹·앱)은 좌표가 항상 숫자라고 믿고 만들어져 있습니다.
    """
    rows, skipped = [], 0
    for item in raw_items:
        row = to_spot_row(item, source=source)
        if row is None:  # 받지 않는 유형이거나 이름이 없는 것
            continue
        if row["lat"] is None or row["lng"] is None:
            skipped += 1
            continue
        rows.append(row)
    return rows, skipped


# 돌려주는 숫자는 종료 코드입니다. 0 = 성공, 1 = 실패로, 맨 아래 sys.exit(main()) 가 터미널에 전달합니다.
def main() -> int:
    parser = argparse.ArgumentParser(description="관광 데이터 가져오기")
    parser.add_argument("--sample", action="store_true", help="샘플 데이터를 넣습니다")
    parser.add_argument("--places", action="store_true", help="편의 시설 샘플(숙소 · 병원 · 약국 · 편의점 · 교통)을 넣습니다")
    parser.add_argument("--restaurants", action="store_true", help="추천 식당 샘플(한식 · 해산물 · 고기구이 · 국수 · 카페)을 넣습니다")
    parser.add_argument("--types", default="12,14,15,28,38,39", help="받을 콘텐츠 유형(쉼표로 구분)")
    parser.add_argument("--limit", type=int, default=100, help="유형마다 받을 최대 건수")
    parser.add_argument("--overview", type=int, default=0, help="소개 글을 받을 건수(0 이면 받지 않음)")
    parser.add_argument("--dry-run", action="store_true", help="DB 에 넣지 않고 결과만 봅니다")
    args = parser.parse_args()

    if args.places or args.restaurants:
        rows = to_place_rows(load_restaurants() if args.restaurants else load_places())
        print(f"{'추천 식당' if args.restaurants else '편의 시설'} {len(rows)}건 (분류를 골랐을 때만 목록에 나옵니다)")
        for name in sorted({row["category"] for row in rows}):
            print(f"  - {name}: {sum(1 for row in rows if row['category'] == name)}건")
        if args.dry_run:
            print("(--dry-run: DB 에 넣지 않았습니다)")
            return 0
        from repo import get_repo

        print(f"DB 에 {get_repo().upsert_spots(rows)}건을 넣었습니다(이미 있던 것은 새 값으로 고침).")
        return 0

    if args.sample:
        source, raw_items = "sample", load_sample()
    else:
        if not settings.tour_api_key:
            print("TOUR_API_KEY 가 없습니다. api/.env 에 넣거나 --sample 로 샘플을 넣어 보세요.")
            return 1
        source, raw_items = "tourapi", []
        for content_type in [t.strip() for t in args.types.split(",") if t.strip()]:
            if content_type not in CATEGORY_BY_TYPE:
                print(f"- 유형 {content_type} 은(는) 받지 않는 유형이라 건너뜁니다.")
                continue
            items = fetch_tour_list(content_type, args.limit)
            print(f"- 유형 {content_type}({CATEGORY_BY_TYPE[content_type]}): {len(items)}건")
            raw_items.extend(items)
        for item in raw_items[: args.overview]:
            item["overview"] = fetch_overview(str(item.get("contentid")))

    rows, skipped = to_rows(raw_items, source)
    print(f"원본 {len(raw_items)}건 → 넣을 수 있는 것 {len(rows)}건" + (f" (좌표가 없어 뺀 것 {skipped}건)" if skipped else ""))
    for row in rows[:3]:
        print(f"  예) {row['title']} | {row['category']} | {row['area']} | {row['theme_tags']} | 실내={row['indoor']}")

    if args.dry_run:
        print("(--dry-run: DB 에 넣지 않았습니다)")
        return 0

    from repo import get_repo  # DB 설정이 없어도 --dry-run 은 돌 수 있게 여기서 불러옵니다

    saved = get_repo().upsert_spots(rows)
    print(f"DB 에 {saved}건을 넣었습니다(이미 있던 것은 새 값으로 고침).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

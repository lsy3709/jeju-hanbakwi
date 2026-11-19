"""관광 데이터를 가져와 우리 기준으로 고친 뒤 DB 에 넣는 도구.

api 폴더에서 실행합니다.

  python -m tools.sync_spots --sample            샘플 68건 넣기 (키 없이 가능)
  python -m tools.sync_spots                     TourAPI 에서 제주 데이터 받아 넣기 (TOUR_API_KEY 필요)
  python -m tools.sync_spots --types 12,14       받을 콘텐츠 유형 고르기
  python -m tools.sync_spots --overview 40       소개 글도 받기 (한 건당 호출 1번 → 하루 한도 주의)
  python -m tools.sync_spots --dry-run           DB 에 넣지 않고 결과만 보기

내 주제로 바꿀 때: --types 로 받을 유형을 고르고, transform.py 의 규칙을 고칩니다.
"""

import argparse
import json
import sys
from pathlib import Path

import httpx

from config import settings
from transform import CATEGORY_BY_TYPE, to_spot_row

SAMPLE_FILE = Path(__file__).parent.parent / "data" / "sample_spots.json"
JEJU_AREA_CODE = "39"  # TourAPI 의 지역 번호: 39 = 제주도


def load_sample() -> list[dict]:
    return json.loads(SAMPLE_FILE.read_text(encoding="utf-8"))


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
    items = body.get("items") or {}
    if not items:  # 결과가 없으면 items 가 빈 글자("")로 옵니다
        return []
    item = items.get("item", [])
    return item if isinstance(item, list) else [item]


def fetch_tour_list(content_type: str, limit: int) -> list[dict]:
    """제주의 한 유형을 limit 건까지 받습니다. (한 번에 100건씩)"""
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


def main() -> int:
    parser = argparse.ArgumentParser(description="관광 데이터 가져오기")
    parser.add_argument("--sample", action="store_true", help="샘플 데이터를 넣습니다")
    parser.add_argument("--types", default="12,14,15,28,38,39", help="받을 콘텐츠 유형(쉼표로 구분)")
    parser.add_argument("--limit", type=int, default=100, help="유형마다 받을 최대 건수")
    parser.add_argument("--overview", type=int, default=0, help="소개 글을 받을 건수(0 이면 받지 않음)")
    parser.add_argument("--dry-run", action="store_true", help="DB 에 넣지 않고 결과만 봅니다")
    args = parser.parse_args()

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

    rows = [row for row in (to_spot_row(item, source=source) for item in raw_items) if row]
    print(f"원본 {len(raw_items)}건 → 넣을 수 있는 것 {len(rows)}건")
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

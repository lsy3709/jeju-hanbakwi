"""데이터 가져오기 도구에서 DB 에 넣을 줄을 고르는 부분."""

from tools.sync_spots import to_rows

GOOD = {
    "contentid": "1",
    "contenttypeid": "12",
    "title": "좋은 곳",
    "addr1": "제주특별자치도 제주시",
    "mapx": "126.5",
    "mapy": "33.5",
}


def test_rows_without_coordinates_are_skipped():
    """좌표가 없는 곳은 지도에 찍을 수 없고, 화면은 좌표가 항상 숫자라고 믿으므로 넣지 않습니다."""
    raw = [GOOD, {**GOOD, "contentid": "2", "mapx": "", "mapy": ""}, {**GOOD, "contentid": "3", "mapx": "0", "mapy": "0"}]
    rows, skipped = to_rows(raw, source="tourapi")
    assert [r["source_id"] for r in rows] == ["1"]
    assert skipped == 2


def test_unknown_type_is_not_counted_as_missing_coordinates():
    rows, skipped = to_rows([GOOD, {**GOOD, "contentid": "9", "contenttypeid": "32"}], source="tourapi")
    assert len(rows) == 1 and skipped == 0

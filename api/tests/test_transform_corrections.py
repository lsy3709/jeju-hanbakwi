"""규칙이 틀리는 곳을 바로잡는 표(CORRECTIONS).

낱말 규칙은 편하지만 완벽하지 않습니다. "용암동굴이 있는 공원"을 실내로 보거나,
"바다가 내려다보이는 오름"에 바다 태그를 붙입니다. 틀린 것을 발견하면 표에 한 줄 더합니다.
"""

# 진짜 샘플 데이터(api/data/sample_spots.json)를 변환해 보고, 틀리기 쉬운 곳이 바로잡혔는지 이름으로 찾아 확인합니다.
import json
from pathlib import Path

from transform import CORRECTIONS, apply_corrections, to_spot_row

SAMPLE = json.loads((Path(__file__).parent.parent / "data" / "sample_spots.json").read_text(encoding="utf-8"))


def row_of(title: str) -> dict:
    raw = next(item for item in SAMPLE if item["title"] == title)
    return to_spot_row(raw, source="sample")


def test_park_with_a_cave_is_outdoor():
    assert row_of("한림공원")["indoor"] is False
    assert row_of("제주돌문화공원")["indoor"] is False


def test_real_indoor_places_stay_indoor():
    assert row_of("만장굴")["indoor"] is True
    assert row_of("아쿠아플라넷 제주")["indoor"] is True


def test_hill_that_only_overlooks_the_sea_has_no_sea_tag():
    for title in ("새별오름", "금오름", "산방산"):
        tags = row_of(title)["theme_tags"]
        assert "바다" not in tags, title
        assert "오름" in tags, title  # 다른 태그는 그대로


def test_real_seaside_places_keep_the_sea_tag():
    assert "바다" in row_of("협재해수욕장")["theme_tags"]
    assert "바다" in row_of("정방폭포")["theme_tags"]  # 바다로 떨어지는 폭포


def test_food_street_near_a_market_is_not_a_market():
    assert "시장" not in row_of("흑돼지거리")["theme_tags"]
    assert "시장" in row_of("동문재래시장")["theme_tags"]


def test_apply_corrections_adds_and_removes():
    row = {"title": "가짜 장소", "indoor": True, "theme_tags": ["바다", "숲"]}
    fixed = apply_corrections(row, {"가짜 장소": {"indoor": False, "remove_tags": ["바다"], "add_tags": ["사진", "숲"]}})
    assert fixed["indoor"] is False
    assert fixed["theme_tags"] == ["숲", "사진"]  # 뺀 것은 빠지고, 더한 것은 중복 없이 뒤에
    assert row["theme_tags"] == ["바다", "숲"]  # 원래 값은 건드리지 않음


def test_place_not_in_the_table_is_unchanged():
    row = {"title": "표에 없는 곳", "indoor": True, "theme_tags": ["바다"]}
    assert apply_corrections(row, CORRECTIONS) == row


def test_every_correction_names_a_known_field():
    """표에 오타가 있으면(예: "indor") 조용히 무시되지 않도록 막습니다."""
    for title, change in CORRECTIONS.items():
        assert set(change) <= {"indoor", "add_tags", "remove_tags"}, title

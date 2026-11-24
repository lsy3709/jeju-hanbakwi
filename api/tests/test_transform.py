"""외부 데이터 한 건이 우리 기준으로 바르게 바뀌는지."""

# RAW 는 TourAPI 가 실제로 주는 모양의 원본 한 건입니다(필드 이름이 우리 것과 다름). 테스트마다 일부 칸만 바꿔 규칙을 확인합니다.
from transform import make_one_liner, pick_area, to_spot_row

RAW = {
    "contentid": "126508",
    "contenttypeid": "12",
    "title": "정방폭포",
    "addr1": "제주특별자치도 서귀포시 칠십리로214번길 37",
    "mapx": "126.5718",
    "mapy": "33.2448",
    "firstimage": "http://tong.visitkorea.or.kr/cms/resource/00/1234_image2_1.jpg",
    "overview": "폭포수가 바다로 바로 떨어지는 해안 폭포이다.<br />계단을 내려가면 가까이에서 볼 수 있다.",
}


def test_basic_fields_are_mapped():
    row = to_spot_row(RAW)
    assert row["source"] == "tourapi"
    assert row["source_id"] == "126508"
    assert row["title"] == "정방폭포"
    assert row["category"] == "관광지"
    assert row["area"] == "서귀포시"
    # mapy 가 위도, mapx 가 경도
    assert row["lat"] == 33.2448
    assert row["lng"] == 126.5718


def test_image_is_switched_to_https():
    assert to_spot_row(RAW)["image_url"].startswith("https://")


def test_empty_image_becomes_none():
    assert to_spot_row({**RAW, "firstimage": ""})["image_url"] is None


def test_html_tags_are_removed_from_overview():
    overview = to_spot_row(RAW)["overview"]
    assert "<br" not in overview
    assert "바다로 바로 떨어지는" in overview


def test_theme_tags_come_from_title_and_overview():
    tags = to_spot_row(RAW)["theme_tags"]
    assert "폭포" in tags
    assert "바다" in tags


def test_museum_type_is_indoor():
    row = to_spot_row({**RAW, "contenttypeid": "14", "title": "어느 전시 공간", "overview": ""})
    assert row["category"] == "문화시설"
    assert row["indoor"] is True


def test_outdoor_by_default_and_indoor_by_keyword():
    assert to_spot_row(RAW)["indoor"] is False
    assert to_spot_row({**RAW, "title": "만장굴", "overview": "용암동굴이다."})["indoor"] is True


def test_unknown_type_and_missing_title_are_skipped():
    assert to_spot_row({**RAW, "contenttypeid": "32"}) is None  # 숙박은 받지 않음
    assert to_spot_row({**RAW, "title": ""}) is None
    assert to_spot_row({**RAW, "contentid": ""}) is None


def test_bad_coordinates_become_none():
    row = to_spot_row({**RAW, "mapx": "", "mapy": "abc"})
    assert row["lat"] is None and row["lng"] is None


def test_area_from_address():
    assert pick_area("제주특별자치도 제주시 구좌읍 월정리") == "동부"
    assert pick_area("제주특별자치도 서귀포시 안덕면") == "서부"
    assert pick_area("제주특별자치도 서귀포시 서귀동") == "서귀포시"
    assert pick_area("제주특별자치도 제주시 연동") == "제주시"
    assert pick_area("") == "제주시"


def test_one_liner():
    assert make_one_liner("첫 문장입니다. 둘째 문장입니다.", "관광지", "동부") == "첫 문장입니다."
    assert make_one_liner("", "관광지", "동부") == "동부에서 만나는 관광지"
    long = make_one_liner("가" * 100, "관광지", "동부")
    assert len(long) == 60 and long.endswith("…")


# ---------------------------------------------------------------- 사진 출처

def test_photo_credit_is_kept_when_given():
    """샘플처럼 출처가 함께 온 사진은 그 출처를 그대로 싣습니다. (출처 표시는 라이선스의 조건)"""
    row = to_spot_row(
        {**RAW, "image_credit": "홍길동 · CC BY-SA 4.0", "image_source_url": "https://commons.wikimedia.org/wiki/File:X.jpg"},
        source="sample",
    )
    assert row["image_credit"] == "홍길동 · CC BY-SA 4.0"
    assert row["image_source_url"] == "https://commons.wikimedia.org/wiki/File:X.jpg"


def test_tourapi_photo_gets_default_credit():
    row = to_spot_row(RAW)  # TourAPI 원본에는 출처 칸이 없습니다
    assert row["image_credit"] == "한국관광공사"
    assert row["image_source_url"] is None


def test_no_photo_means_no_credit():
    row = to_spot_row({**RAW, "firstimage": "", "image_credit": "누군가"})
    assert row["image_url"] is None
    assert row["image_credit"] is None
    assert row["image_source_url"] is None

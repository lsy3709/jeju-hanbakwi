// 테스트 파일입니다. 화면 없이 spotForm.ts 의 함수 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { MAX_THEMES, createBody, emptySpotForm, patchBody, spotToForm, toggleTheme } from "./spotForm";
import type { AdminSpot } from "./types";

// 수정 폼 테스트에 쓰는 예시 여행지입니다.
const spot: AdminSpot = {
  id: 7,
  title: "성산일출봉",
  category: "관광지",
  area: "동부",
  address: "서귀포시 성산읍",
  lat: 33.45,
  lng: 126.94,
  image_url: null,
  image_credit: null,
  image_source_url: null,
  overview: "긴 소개",
  one_liner: "한 줄",
  theme_tags: ["바다", "오름"],
  indoor: false,
  hidden: false,
  source: "sample",
};

// 테마 칩을 누르면 더해지고 빠지며 5개를 넘지 않는지 확인합니다.
describe("toggleTheme", () => {
  it("없던 테마는 더하고, 있던 테마는 뺀다", () => {
    expect(toggleTheme(["바다"], "숲")).toEqual(["바다", "숲"]);
    expect(toggleTheme(["바다", "숲"], "바다")).toEqual(["숲"]);
  });
  it(`${MAX_THEMES}개가 차 있으면 더 더하지 않는다(빼기는 된다)`, () => {
    const full = ["1", "2", "3", "4", "5"];
    expect(toggleTheme(full, "6")).toEqual(full);
    expect(toggleTheme(full, "3")).toEqual(["1", "2", "4", "5"]);
  });
});

// 추가 폼의 값이 서버로 보낼 본문으로 올바르게 바뀌는지 확인합니다.
describe("createBody (추가 폼 → POST 본문)", () => {
  it("앞뒤 공백을 지우고, 빈 선택 칸(사진·위도·경도)은 보내지 않는다", () => {
    const body = createBody({ ...emptySpotForm(), title: "  새 카페 ", category: "음식점", area: "서부" });
    expect(body).toEqual({
      title: "새 카페",
      category: "음식점",
      area: "서부",
      address: "",
      one_liner: "",
      overview: "",
      theme_tags: [],
      indoor: false,
    });
  });
  it("위도·경도는 숫자로, 사진 주소는 글자로 보낸다", () => {
    const body = createBody({ ...emptySpotForm(), title: "a", lat: "33.5", lng: " 126.5 ", image_url: "https://x.kr/a.jpg" });
    expect(body.lat).toBe(33.5);
    expect(body.lng).toBe(126.5);
    expect(body.image_url).toBe("https://x.kr/a.jpg");
  });
  it("숫자가 아닌 위도는 보내지 않는다", () => {
    expect("lat" in createBody({ ...emptySpotForm(), title: "a", lat: "abc" })).toBe(false);
  });
});

// 수정 폼에서 바뀐 칸만 본문에 담기는지 확인합니다.
describe("patchBody (수정 폼 → PATCH 본문)", () => {
  it("아무것도 바꾸지 않으면 빈 객체", () => {
    expect(patchBody(spot, spotToForm(spot))).toEqual({});
  });
  it("바꾼 칸만 담는다", () => {
    const form = { ...spotToForm(spot), title: "성산 일출봉 ", indoor: true, theme_tags: ["바다"] };
    expect(patchBody(spot, form)).toEqual({ title: "성산 일출봉", indoor: true, theme_tags: ["바다"] });
  });
  it("테마 순서만 같고 내용이 같으면 바뀐 것으로 보지 않는다", () => {
    expect(patchBody(spot, { ...spotToForm(spot), theme_tags: ["바다", "오름"] })).toEqual({});
  });
});

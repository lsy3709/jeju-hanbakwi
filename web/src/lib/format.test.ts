import { describe, expect, it } from "vitest";
import { buildQuery, dayTitle, formatDate, formatSavedAt, pickFallbackTone, spotsQuery, todayString } from "./format";

describe("buildQuery", () => {
  it("값이 있는 항목만 쿼리로 만든다", () => {
    expect(buildQuery({ q: "폭포", theme: "", area: undefined, page: 2 })).toBe("?q=%ED%8F%AD%ED%8F%AC&page=2");
  });
  it("값이 하나도 없으면 빈 문자열", () => {
    expect(buildQuery({ q: "", theme: undefined })).toBe("");
  });
  it("false 도 값으로 취급한다 (indoor=false)", () => {
    expect(spotsQuery({ indoor: false })).toBe("?indoor=false");
  });
});

describe("pickFallbackTone", () => {
  it("바다·폭포는 sea", () => expect(pickFallbackTone(["사진", "바다"])).toBe("sea"));
  it("오름·숲은 green", () => expect(pickFallbackTone(["오름"])).toBe("green"));
  it("그 밖은 sand", () => expect(pickFallbackTone(["카페"])).toBe("sand"));
  it("태그가 없어도 sand", () => expect(pickFallbackTone([])).toBe("sand"));
});

describe("날짜 표시", () => {
  it("요일을 붙인다", () => expect(formatDate("2026-12-01")).toBe("12월 1일 (화)"));
  it("null 이면 null", () => expect(formatDate(null)).toBeNull());
  it("일차 제목", () => {
    expect(dayTitle(1, "2026-12-01")).toBe("1일차 · 12월 1일 (화)");
    expect(dayTitle(2, null)).toBe("2일차");
  });
  it("저장 시각", () => expect(formatSavedAt("2026-12-01T03:00:00+00:00")).toBe("2026년 12월 1일"));
  it("오늘 날짜 문자열", () => expect(todayString(new Date(2026, 0, 5))).toBe("2026-01-05"));
});

import { describe, expect, it } from "vitest";
import { buildQuery, pickFallbackTone } from "./format";

describe("buildQuery", () => {
  it("값이 있는 항목만 쿼리로 만든다", () => {
    expect(buildQuery({ q: "폭포", theme: "", area: undefined, page: 2 })).toBe("?q=%ED%8F%AD%ED%8F%AC&page=2");
  });
  it("값이 하나도 없으면 빈 문자열", () => {
    expect(buildQuery({ q: "", theme: undefined })).toBe("");
  });
  it("false 도 값으로 취급한다 (indoor=false)", () => {
    expect(buildQuery({ indoor: false })).toBe("?indoor=false");
  });
});

describe("pickFallbackTone", () => {
  it("바다·폭포는 sea", () => expect(pickFallbackTone(["사진", "바다"])).toBe("sea"));
  it("오름·숲은 green", () => expect(pickFallbackTone(["오름"])).toBe("green"));
  it("그 밖은 sand", () => expect(pickFallbackTone(["카페"])).toBe("sand"));
  it("태그가 없어도 sand", () => expect(pickFallbackTone([])).toBe("sand"));
});

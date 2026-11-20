import { describe, expect, it } from "vitest";
import { buildQuery, photoCreditText, pickFallbackTone, spotsQuery, weatherText } from "./format";

describe("photoCreditText", () => {
  it("사진과 출처가 있으면 '사진: …' 글자를 만든다", () => {
    expect(photoCreditText({ image_url: "https://x/a.jpg", image_credit: "Jane Doe · CC BY-SA 4.0" })).toBe(
      "사진: Jane Doe · CC BY-SA 4.0",
    );
  });
  it("출처가 없으면 null", () => {
    expect(photoCreditText({ image_url: "https://x/a.jpg", image_credit: null })).toBeNull();
    expect(photoCreditText({ image_url: "https://x/a.jpg", image_credit: "  " })).toBeNull();
  });
  it("사진이 없으면(대체 그림) 출처가 있어도 null", () => {
    expect(photoCreditText({ image_url: null, image_credit: "Jane Doe · CC BY-SA 4.0" })).toBeNull();
  });
});

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

describe("weatherText", () => {
  const base = { temp_min: 8.4, temp_max: 14.6, rain_prob: 30 };
  it("값이 모두 있으면 기온과 강수확률을 함께 보여 준다", () => {
    expect(weatherText(base)).toBe("8° / 15° · 비 30%");
  });
  it("기온이 null 이면 기온 조각을 뺀다", () => {
    expect(weatherText({ ...base, temp_min: null })).toBe("비 30%");
    expect(weatherText({ ...base, temp_max: null })).toBe("비 30%");
  });
  it("강수확률이 null 이면 비 조각을 뺀다", () => {
    expect(weatherText({ ...base, rain_prob: null })).toBe("8° / 15°");
  });
  it("전부 null 이면 빈 문자열", () => {
    expect(weatherText({ temp_min: null, temp_max: null, rain_prob: null })).toBe("");
  });
});

import { describe, expect, it } from "vitest";
import { findSpots, getSpot, SPOTS } from "./spots";

describe("findSpots", () => {
  it("조건이 없으면 전부 돌려준다", () => {
    expect(findSpots()).toHaveLength(SPOTS.length);
  });
  it("검색어는 이름이나 한 줄 소개에서 찾는다", () => {
    expect(findSpots({ q: "폭포" }).map((s) => s.title)).toEqual(["천지연폭포"]);
  });
  it("테마는 태그에서 찾는다", () => {
    const sea = findSpots({ theme: "바다" });
    expect(sea.length).toBeGreaterThan(1);
    expect(sea.every((s) => s.theme_tags.includes("바다"))).toBe(true);
  });
  it("검색어와 테마를 함께 쓰면 둘 다 맞는 것만 남고, 없으면 빈 목록", () => {
    expect(findSpots({ q: "일출", theme: "바다" }).map((s) => s.title)).toEqual(["성산일출봉"]);
    expect(findSpots({ q: "없는이름" })).toEqual([]);
  });
});

describe("getSpot", () => {
  it("id 로 하나를 찾는다", () => {
    expect(getSpot("1")?.title).toBe("성산일출봉");
  });
  it("없는 id 나 숫자가 아닌 id 는 undefined", () => {
    expect(getSpot("9999")).toBeUndefined();
    expect(getSpot("abc")).toBeUndefined();
  });
});

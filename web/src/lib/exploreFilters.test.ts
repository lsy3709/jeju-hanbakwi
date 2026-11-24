// 테스트 파일입니다. 화면 없이 exploreFilters.ts 의 함수 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { exploreHref, hasActiveFilter, parseExploreQuery } from "./exploreFilters";

const parse = (query: string) => parseExploreQuery(new URLSearchParams(query));

// 주소의 쿼리가 필터로 올바르게 읽히는지 확인합니다.
describe("parseExploreQuery (주소 쿼리 → 필터)", () => {
  it("쿼리가 비어 있으면 모든 필터가 비어 있다", () => {
    const state = parse("");
    expect(state.filters).toEqual({
      q: undefined,
      theme: undefined,
      area: undefined,
      category: undefined,
      indoor: undefined,
    });
    expect(state.isMap).toBe(false);
    expect(hasActiveFilter(state.filters)).toBe(false);
  });
  it("값이 있는 항목을 필터로 옮긴다", () => {
    const state = parse("q=폭포&theme=바다&area=서귀포시&category=관광지");
    expect(state.filters).toMatchObject({ q: "폭포", theme: "바다", area: "서귀포시", category: "관광지" });
    expect(hasActiveFilter(state.filters)).toBe(true);
  });
  it("빈 값(q=)은 undefined 로 취급한다", () => {
    expect(parse("q=&area=").filters.q).toBeUndefined();
    expect(parse("q=&area=").filters.area).toBeUndefined();
  });
  it('indoor: "true" → true, "false" → false, "" 또는 없음 → undefined', () => {
    expect(parse("indoor=true").filters.indoor).toBe(true);
    expect(parse("indoor=false").filters.indoor).toBe(false);
    expect(parse("indoor=").filters.indoor).toBeUndefined();
    expect(parse("").filters.indoor).toBeUndefined();
  });
  it("view=map 이면 지도 보기", () => {
    expect(parse("view=map").isMap).toBe(true);
    expect(parse("view=list").isMap).toBe(false);
  });
  it("view 는 필터가 아니므로 hasActiveFilter 에 영향이 없다", () => {
    expect(hasActiveFilter(parse("view=map").filters)).toBe(false);
  });
});

// 필터를 바꿨을 때 만들어지는 새 주소가 맞는지 확인합니다(한글은 %로 시작하는 글자로 바뀌어 주소에 들어갑니다).
describe("exploreHref (바뀐 값으로 다음 주소 만들기)", () => {
  it("바뀐 값만 덮어쓰고 나머지는 유지한다", () => {
    const state = parse("q=폭포&area=동부");
    expect(exploreHref("/explore", state, { theme: "바다" })).toBe(
      "/explore?q=%ED%8F%AD%ED%8F%AC&theme=%EB%B0%94%EB%8B%A4&area=%EB%8F%99%EB%B6%80",
    );
  });
  it("값을 빈 문자열로 바꾸면 그 항목이 주소에서 빠진다", () => {
    expect(exploreHref("/explore", parse("area=동부"), { area: "" })).toBe("/explore");
  });
  it("지도 보기(view=map)는 다른 필터를 바꿔도 유지된다", () => {
    const href = exploreHref("/explore", parse("view=map"), { indoor: "true" });
    expect(href).toBe("/explore?indoor=true&view=map");
  });
  it("view 를 빈 값으로 바꾸면 목록 보기로 돌아간다", () => {
    expect(exploreHref("/explore", parse("view=map"), { view: "" })).toBe("/explore");
  });
  it("indoor 는 글자 그대로 유지한다", () => {
    expect(exploreHref("/explore", parse("indoor=false"), { q: "a" })).toBe("/explore?q=a&indoor=false");
  });
});

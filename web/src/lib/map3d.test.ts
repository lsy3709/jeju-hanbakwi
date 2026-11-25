import { describe, expect, it } from "vitest";
import { boundsOf, metersPerPixel, modelHeightMeters, terrainStyle } from "./map3d";

describe("boundsOf (핀을 모두 담는 범위)", () => {
  it("곳이 없으면 null", () => {
    expect(boundsOf([])).toBeNull();
  });
  it("[서쪽·남쪽], [동쪽·북쪽] 순서로 돌려준다 (경도가 먼저)", () => {
    const spots = [
      { id: 1, title: "가", lat: 33.5, lng: 126.5 },
      { id: 2, title: "나", lat: 33.2, lng: 126.9 },
    ];
    expect(boundsOf(spots)).toEqual([
      [126.5, 33.2],
      [126.9, 33.5],
    ]);
  });
});

describe("metersPerPixel (화면 1픽셀이 실제 몇 미터인지)", () => {
  it("한 단계 확대하면 절반이 된다", () => {
    expect(metersPerPixel(10, 33.4)).toBeCloseTo(metersPerPixel(9, 33.4) / 2, 6);
  });
  it("적도, 확대 0 에서는 지구 둘레 / 512", () => {
    expect(metersPerPixel(0, 0)).toBeCloseTo(40075016.686 / 512, 3);
  });
});

describe("modelHeightMeters (모델을 화면에서 늘 비슷한 크기로)", () => {
  it("멀리서 볼수록(확대가 작을수록) 모델을 크게 만든다", () => {
    expect(modelHeightMeters(8, 33.4)).toBeGreaterThan(modelHeightMeters(12, 33.4));
  });
  it("화면에서의 높이(픽셀)에 비례한다", () => {
    expect(modelHeightMeters(10, 33.4, 120)).toBeCloseTo(modelHeightMeters(10, 33.4, 60) * 2, 6);
  });
});

describe("terrainStyle (지도 모양 설정)", () => {
  const style = terrainStyle();
  it("바탕 지도와 높이 자료(땅 세우기용 · 그림자용)를 쓴다", () => {
    expect(Object.keys(style.sources).sort()).toEqual(["dem", "osm", "shade"]);
  });
  it("높이 자료로 땅을 세운다", () => {
    expect(style.terrain?.source).toBe("dem");
  });
  it("출처 표기가 들어 있다", () => {
    expect(JSON.stringify(style.sources)).toContain("OpenStreetMap");
  });
});

import { describe, expect, it } from "vitest";
import { BOUNDS, cameraPullBack, inBounds, lngLatToModel, SIZE_X, SIZE_Z } from "./fantasyMap";

describe("lngLatToModel (경도 · 위도 → 판타지 지도 모델의 자리)", () => {
  it("네모의 가운데는 원점", () => {
    const mid = lngLatToModel((BOUNDS.west + BOUNDS.east) / 2, (BOUNDS.south + BOUNDS.north) / 2);
    expect(mid.x).toBeCloseTo(0, 6);
    expect(mid.z).toBeCloseTo(0, 6);
  });
  it("동쪽 끝은 +x, 서쪽 끝은 -x (가로 길이 10)", () => {
    expect(lngLatToModel(BOUNDS.east, 33.3).x).toBeCloseTo(SIZE_X / 2, 6);
    expect(lngLatToModel(BOUNDS.west, 33.3).x).toBeCloseTo(-SIZE_X / 2, 6);
  });
  it("북쪽은 -z, 남쪽은 +z (화면에서 북쪽이 멀리 보이게)", () => {
    expect(lngLatToModel(126.5, BOUNDS.north).z).toBeCloseTo(-SIZE_Z / 2, 6);
    expect(lngLatToModel(126.5, BOUNDS.south).z).toBeCloseTo(SIZE_Z / 2, 6);
  });
  it("한라산은 가운데에서 살짝 서쪽", () => {
    const hallasan = lngLatToModel(126.5332, 33.3617);
    expect(hallasan.x).toBeLessThan(0);
    expect(Math.abs(hallasan.x)).toBeLessThan(0.5);
  });
});

describe("SIZE_Z (세로 길이는 실제 비율대로)", () => {
  it("블렌더 스크립트가 찍어 준 값(6.598)과 같다", () => {
    expect(SIZE_Z).toBeCloseTo(6.598, 3);
  });
});

describe("cameraPullBack (좁은 화면에서 카메라를 얼마나 뒤로 뺄지)", () => {
  it("넓은 화면에서는 그대로(1배)", () => {
    expect(cameraPullBack(1280 / 800)).toBe(1);
  });
  it("세로로 긴 화면일수록 더 뒤로 뺀다", () => {
    expect(cameraPullBack(0.75)).toBeGreaterThan(cameraPullBack(1));
    expect(cameraPullBack(0.75)).toBeCloseTo(1.6, 6);
  });
  it("아무리 좁아도 2.4배를 넘지 않는다", () => {
    expect(cameraPullBack(0.1)).toBe(2.4);
  });
});

describe("inBounds (모델 안에 있는 곳인지)", () => {
  it("제주 안은 참, 서울은 거짓", () => {
    expect(inBounds(126.53, 33.5)).toBe(true);
    expect(inBounds(126.98, 37.57)).toBe(false);
  });
});

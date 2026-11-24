// 테스트 파일입니다. 화면 없이 mapSpots.ts 의 withLocation 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { withLocation } from "./mapSpots";

describe("withLocation", () => {
  it("위치가 있는 곳만 남긴다", () => {
    const spots = [
      { id: 1, title: "가", lat: 33.4, lng: 126.5 },
      { id: 2, title: "나", lat: null, lng: null },
      { id: 3, title: "다", lat: 33.2, lng: null },
    ];
    expect(withLocation(spots).map((s) => s.id)).toEqual([1]);
  });

  it("위도 0 처럼 거짓으로 읽히는 숫자도 위치로 본다", () => {
    expect(withLocation([{ id: 1, title: "가", lat: 0, lng: 0 }])).toHaveLength(1);
  });

  it("모두 위치가 없으면 빈 목록", () => {
    expect(withLocation([{ id: 2, title: "나", lat: null, lng: null }])).toEqual([]);
  });
});

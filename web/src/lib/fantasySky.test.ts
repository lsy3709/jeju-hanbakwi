import { describe, expect, it } from "vitest";
import { dayness, jejuHour, mixColor, nextSkyMode, skyLabel } from "./fantasySky";

describe("jejuHour (지금 제주가 몇 시인지)", () => {
  it("세계 표준시에 9시간을 더한다", () => {
    expect(jejuHour(new Date("2026-11-26T03:30:00Z"))).toBeCloseTo(12.5, 6);
  });
  it("자정을 넘으면 0시부터 다시 센다", () => {
    expect(jejuHour(new Date("2026-11-26T18:00:00Z"))).toBeCloseTo(3, 6);
  });
});

describe("dayness (얼마나 낮인지 — 0 은 밤, 1 은 낮)", () => {
  it("한낮은 1, 한밤은 0", () => {
    expect(dayness(12)).toBe(1);
    expect(dayness(0)).toBe(0);
    expect(dayness(23)).toBe(0);
  });
  it("새벽 5시 ~ 7시에 서서히 밝아진다", () => {
    expect(dayness(5)).toBe(0);
    expect(dayness(6)).toBeCloseTo(0.5, 6);
    expect(dayness(7)).toBe(1);
  });
  it("저녁 18시 ~ 20시에 서서히 어두워진다", () => {
    expect(dayness(18)).toBe(1);
    expect(dayness(19)).toBeCloseTo(0.5, 6);
    expect(dayness(20)).toBe(0);
  });
});

describe("mixColor (밤 색과 낮 색을 섞기)", () => {
  it("0 이면 밤 색, 1 이면 낮 색, 0.5 면 가운데", () => {
    expect(mixColor(0x000000, 0xffffff, 0)).toBe(0x000000);
    expect(mixColor(0x000000, 0xffffff, 1)).toBe(0xffffff);
    expect(mixColor(0x000000, 0xff8040, 0.5)).toBe(0x804020);
  });
});

describe("nextSkyMode · skyLabel (전환 단추)", () => {
  it("지금 시각 → 낮 → 밤 → 지금 시각 순서로 돈다", () => {
    expect(nextSkyMode("auto")).toBe("day");
    expect(nextSkyMode("day")).toBe("night");
    expect(nextSkyMode("night")).toBe("auto");
  });
  it("단추에 보일 글자", () => {
    expect(skyLabel("auto")).toBe("지금 시각");
    expect(skyLabel("day")).toBe("낮");
    expect(skyLabel("night")).toBe("밤");
  });
});

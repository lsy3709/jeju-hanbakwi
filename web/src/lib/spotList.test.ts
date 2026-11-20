import { describe, expect, it } from "vitest";
import { appendPage } from "./spotList";
import type { Spot } from "./types";

const spot = (id: number) => ({ id, title: `장소${id}` }) as Spot;
const prev = { key: "q=a", items: [spot(1), spot(2)], total: 5, page: 1, error: null as string | null };

describe("appendPage", () => {
  it("같은 필터(key)면 다음 쪽을 뒤에 이어 붙인다", () => {
    const next = { items: [spot(3)], total: 5, page: 2, size: 20 };
    const result = appendPage(prev, "q=a", next);
    expect(result?.items.map((s) => s.id)).toEqual([1, 2, 3]);
    expect(result?.page).toBe(2);
    expect(result?.total).toBe(5);
  });
  it("그사이 필터가 바뀌었으면(key 가 다르면) 늦게 온 응답을 버리고 prev 를 그대로 둔다", () => {
    const next = { items: [spot(3)], total: 5, page: 2, size: 20 };
    expect(appendPage(prev, "q=b", next)).toBe(prev);
  });
  it("prev 가 null 이면 null", () => {
    const next = { items: [spot(3)], total: 5, page: 2, size: 20 };
    expect(appendPage(null, "q=a", next)).toBeNull();
  });
});

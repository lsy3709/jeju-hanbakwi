// 테스트 파일입니다. 화면 없이 cursorList.ts 의 함수 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { appendPage, failedFirstPage, firstPage, prependItem, removeItem, replaceItem, withError } from "./cursorList";

type Row = { id: number; name: string };
const row = (id: number): Row => ({ id, name: `줄${id}` });
const ids = (list: { items: Row[] } | null) => list?.items.map((r) => r.id);

// 첫 묶음으로 목록 상태를 만드는 함수를 확인합니다.
describe("firstPage", () => {
  it("첫 묶음의 items · next_cursor · total 을 기억한다", () => {
    const list = firstPage("q=a", { items: [row(1), row(2)], next_cursor: 2, total: 5 });
    expect(list).toEqual({ key: "q=a", items: [row(1), row(2)], nextCursor: 2, total: 5, error: null });
  });
  it("total 이 없는 목록(찜·일정)은 total 을 null 로 둔다", () => {
    expect(firstPage("k", { items: [], next_cursor: null }).total).toBeNull();
  });
});

// 첫 불러오기 실패 상태를 확인합니다.
describe("failedFirstPage", () => {
  it("빈 목록에 오류 문구만 담는다", () => {
    expect(failedFirstPage("k", "서버 오류")).toEqual({ key: "k", items: [], nextCursor: null, total: null, error: "서버 오류" });
  });
});

// "더 보기" 결과 이어 붙이기(중복 제거, 늦게 온 응답 버리기 포함)를 확인합니다.
describe("appendPage", () => {
  const prev = firstPage("q=a", { items: [row(1), row(2)], next_cursor: 2, total: 5 });

  it("같은 key 면 다음 묶음을 뒤에 이어 붙이고 커서를 바꾼다", () => {
    const next = appendPage(prev, "q=a", { items: [row(3)], next_cursor: 3, total: null });
    expect(ids(next)).toEqual([1, 2, 3]);
    expect(next?.nextCursor).toBe(3);
  });
  it("이어지는 묶음의 total 은 null 이므로 첫 묶음의 total 을 그대로 둔다", () => {
    expect(appendPage(prev, "q=a", { items: [row(3)], next_cursor: null, total: null })?.total).toBe(5);
  });
  it("마지막 묶음이면 nextCursor 가 null 이 된다", () => {
    expect(appendPage(prev, "q=a", { items: [row(3)], next_cursor: null })?.nextCursor).toBeNull();
  });
  it("이미 있는 id 는 두 번 넣지 않는다", () => {
    expect(ids(appendPage(prev, "q=a", { items: [row(2), row(3)], next_cursor: null }))).toEqual([1, 2, 3]);
  });
  it("더 보기에 성공하면 앞의 오류 문구를 지운다", () => {
    const failed = withError(prev, "q=a", "잠시 끊김");
    expect(appendPage(failed, "q=a", { items: [row(3)], next_cursor: null })?.error).toBeNull();
  });
  it("그사이 key(필터)가 바뀌었으면 늦게 온 응답을 버리고 prev 를 그대로 둔다", () => {
    expect(appendPage(prev, "q=b", { items: [row(3)], next_cursor: null })).toBe(prev);
  });
  it("prev 가 null 이면 null", () => {
    expect(appendPage(null, "q=a", { items: [row(3)], next_cursor: null })).toBeNull();
  });
});

// 더 보기 실패 시 오류 문구만 붙는지 확인합니다.
describe("withError", () => {
  const prev = firstPage("k", { items: [row(1)], next_cursor: 1 });
  it("같은 key 면 목록은 두고 오류 문구만 붙인다", () => {
    const next = withError(prev, "k", "실패");
    expect(ids(next)).toEqual([1]);
    expect(next?.error).toBe("실패");
  });
  it("key 가 다르면 prev 를 그대로 둔다", () => {
    expect(withError(prev, "other", "실패")).toBe(prev);
  });
});

// 목록에서 한 줄을 뺄 때 개수와 커서가 맞는지 확인합니다.
describe("removeItem", () => {
  it("그 id 의 줄을 빼고 total 을 하나 줄인다(커서는 그대로)", () => {
    const prev = firstPage("k", { items: [row(1), row(2)], next_cursor: 2, total: 5 });
    const next = removeItem(prev, 1);
    expect(ids(next)).toEqual([2]);
    expect(next?.total).toBe(4);
    expect(next?.nextCursor).toBe(2);
  });
  it("total 을 모르는 목록은 null 로 둔다", () => {
    expect(removeItem(firstPage("k", { items: [row(1)], next_cursor: null }), 1)?.total).toBeNull();
  });
  it("없는 id 면 아무것도 바꾸지 않는다", () => {
    const prev = firstPage("k", { items: [row(1)], next_cursor: null, total: 1 });
    expect(removeItem(prev, 9)).toBe(prev);
  });
  it("prev 가 null 이면 null", () => {
    expect(removeItem<Row>(null, 1)).toBeNull();
  });
});

// 한 줄만 새 값으로 바뀌는지 확인합니다.
describe("replaceItem", () => {
  it("같은 id 의 줄만 새 값으로 바꾸고 순서는 그대로 둔다", () => {
    const prev = firstPage("k", { items: [row(1), row(2), row(3)], next_cursor: null });
    const next = replaceItem(prev, { id: 2, name: "고친 줄" });
    expect(next?.items.map((r) => r.name)).toEqual(["줄1", "고친 줄", "줄3"]);
  });
});

// 새 줄이 맨 앞에 들어가는지 확인합니다.
describe("prependItem", () => {
  it("새 줄을 맨 앞에 넣고 total 을 하나 늘린다", () => {
    const prev = firstPage("k", { items: [row(1)], next_cursor: null, total: 1 });
    const next = prependItem(prev, row(9));
    expect(ids(next)).toEqual([9, 1]);
    expect(next?.total).toBe(2);
  });
});

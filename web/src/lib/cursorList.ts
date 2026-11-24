// 커서로 나눠 받는 목록("더 보기")을 다루는 순수 함수입니다. 탐색 · 내 여행 · 관리자 화면이 함께 씁니다.
// React 와 무관해서 화면 없이 테스트할 수 있어요(cursorList.test.ts).
// 쓰는 곳: hooks/useCursorList.ts 와 목록 화면의 훅들. 여기 함수들은 "이전 목록 + 새 정보 → 새 목록"을 만들 뿐, 서버를 부르지 않습니다.
// 낱말 풀이: 커서 = "여기까지 받았다"는 표시 번호입니다. 다음 묶음을 달라고 할 때 그 번호를 돌려보냅니다.
// "..." (펼치기) 는 기존 값을 복사해 일부만 바꾼 새 값을 만드는 문법입니다. 원래 목록을 직접 고치지 않아야 화면이 바뀐 것을 알아챕니다.
import type { CursorPage } from "./types";

/** 목록에 들어가는 줄은 모두 id 가 있습니다(관광지·일정은 숫자, 사용자는 UUID 글자). */
type WithId = { id: number | string };

/**
 * 화면이 들고 있는 목록 상태.
 * - key: 어떤 필터로 받은 목록인지. 필터가 바뀌면 key 도 바뀝니다.
 * - nextCursor: 다음 묶음을 받을 때 cursor 로 돌려보낼 값. null 이면 끝(= "더 보기"를 숨김).
 * - total: 전체 개수. 첫 묶음에서만 오므로 그 값을 기억해 둡니다(모르면 null).
 */
export type CursorList<T> = {
  key: string;
  items: T[];
  nextCursor: number | null;
  total: number | null;
  error: string | null;
};

/** total 이 있는 목록(/spots, /admin/spots)과 없는 목록(찜·일정·사용자)을 함께 받습니다. */
type Page<T> = CursorPage<T> & { total?: number | null };

/** 첫 묶음으로 새 목록을 만듭니다. */
export function firstPage<T>(key: string, page: Page<T>): CursorList<T> {
  return { key, items: page.items, nextCursor: page.next_cursor, total: page.total ?? null, error: null };
}

/** 첫 묶음부터 실패했을 때의 목록(빈 목록 + 오류 문구). */
export function failedFirstPage<T>(key: string, error: string): CursorList<T> {
  return { key, items: [], nextCursor: null, total: null, error };
}

/**
 * "더 보기"로 받은 다음 묶음(page)을 prev 뒤에 이어 붙입니다.
 * 왜 key 를 비교하나: 응답을 기다리는 사이 필터가 바뀌었을 수 있습니다.
 * 그때 옛 필터의 결과를 붙이면 엉뚱한 목록이 되므로, 늦게 온 응답은 버리고 prev 를 그대로 둡니다.
 * 왜 id 를 확인하나: 같은 줄이 두 번 그려지면 React 가 key 중복 경고를 내므로 한 번 더 걸러 둡니다.
 */
export function appendPage<T extends WithId>(
  prev: CursorList<T> | null,
  requestKey: string,
  page: Page<T>,
): CursorList<T> | null {
  if (!prev || prev.key !== requestKey) return prev;
  const seen = new Set(prev.items.map((item) => item.id));
  const fresh = page.items.filter((item) => !seen.has(item.id));
  return {
    ...prev,
    items: [...prev.items, ...fresh],
    nextCursor: page.next_cursor,
    // 이어지는 묶음의 total 은 null 이라 첫 값을 지킵니다.
    total: prev.total ?? page.total ?? null,
    error: null,
  };
}

/** "더 보기"가 실패했을 때: 받아 둔 목록은 그대로 두고 오류 문구만 붙입니다. */
export function withError<T>(prev: CursorList<T> | null, requestKey: string, error: string): CursorList<T> | null {
  if (!prev || prev.key !== requestKey) return prev;
  return { ...prev, error };
}

/**
 * 한 줄을 목록에서 뺍니다(찜 해제 · 일정 삭제 뒤).
 * 커서는 "마지막으로 받은 줄의 번호"라서 앞의 줄이 빠져도 다음 묶음은 어긋나지 않습니다. 그래서 nextCursor 는 그대로 둡니다.
 */
export function removeItem<T extends WithId>(prev: CursorList<T> | null, id: T["id"]): CursorList<T> | null {
  if (!prev || !prev.items.some((item) => item.id === id)) return prev;
  return {
    ...prev,
    items: prev.items.filter((item) => item.id !== id),
    total: prev.total === null ? null : Math.max(0, prev.total - 1),
  };
}

/** 같은 id 의 줄만 새 값으로 바꿉니다. 목록 전체를 다시 받지 않으니 스크롤 위치가 그대로입니다. */
export function replaceItem<T extends WithId>(prev: CursorList<T> | null, next: T): CursorList<T> | null {
  if (!prev) return prev;
  return { ...prev, items: prev.items.map((item) => (item.id === next.id ? next : item)) };
}

/** 새로 만든 줄을 맨 앞에 넣습니다(방금 추가한 것을 바로 보이게). 나중에 같은 줄이 묶음으로 오면 appendPage 가 걸러 냅니다. */
export function prependItem<T extends WithId>(prev: CursorList<T> | null, item: T): CursorList<T> | null {
  if (!prev) return prev;
  return { ...prev, items: [item, ...prev.items], total: prev.total === null ? null : prev.total + 1 };
}

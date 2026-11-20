// 탐색 화면의 "더 보기" 결과를 합치는 순수 함수입니다. 테스트하기 쉬워요.
import type { Spot, SpotList } from "./types";

export type Result = { key: string; items: Spot[]; total: number; page: number; error: string | null };

/**
 * "더 보기"로 받은 다음 쪽(next)을 prev 뒤에 이어 붙인 새 결과를 돌려줍니다.
 * 왜: 응답을 기다리는 사이 필터가 바뀌었을 수 있습니다(prev.key !== requestKey).
 * 그때 옛 필터의 결과로 덮어쓰면 화면이 영원히 "불러오는 중"이 되므로, 늦게 온 응답은 버리고 prev 를 그대로 둡니다.
 */
export function appendPage(prev: Result | null, requestKey: string, next: SpotList): Result | null {
  if (!prev || prev.key !== requestKey) return prev;
  return { ...prev, items: [...prev.items, ...next.items], total: next.total, page: next.page };
}

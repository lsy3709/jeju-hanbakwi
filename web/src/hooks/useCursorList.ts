"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: 커서로 나눠 받는 목록의 공통 상태(첫 묶음 · 더 보기 · 다시 불러오기 · 한 줄 고치기/빼기)를 맡는 훅.
// 탐색(useSpotSearch) · 내 여행(useFavorites, useTrips) · 관리자(useAdminUsers, useAdminSpots)가 모두 이 훅 위에 서 있습니다.
// 목록을 합치는 계산은 lib/cursorList.ts 의 순수 함수가 하고, 여기서는 "언제 부를지"만 정합니다.
import { useEffect, useState } from "react";
import { errorMessage } from "@/lib/api";
import {
  appendPage,
  failedFirstPage,
  firstPage,
  prependItem,
  removeItem,
  replaceItem,
  withError,
  type CursorList,
} from "@/lib/cursorList";
import type { CursorPage } from "@/lib/types";

// 목록의 줄마다 id 가 있어야 한 줄만 고치거나 뺄 수 있습니다.
type WithId = { id: number | string };

/**
 * filterKey: 필터를 글자로 만든 값. 바뀌면 커서를 버리고 처음부터 다시 받습니다.
 * fetchPage: cursor(처음에는 null)를 받아 한 묶음을 돌려주는 함수. useCallback 으로 감싸서 넘겨 주세요
 *            (함수가 바뀌면 다시 불러옵니다).
 */
// T 는 목록 한 줄의 모양(관광지·일정·사용자 등)입니다. 이 훅이 돌려주는 값을 각 목록 훅이 골라 화면에 넘깁니다.
export function useCursorList<T extends WithId>(
  filterKey: string,
  fetchPage: (cursor: number | null) => Promise<CursorPage<T> & { total?: number | null }>,
) {
  const [list, setList] = useState<CursorList<T> | null>(null);
  const [reloadTick, setReloadTick] = useState(0);
  const [moreBusy, setMoreBusy] = useState(false);
  // "다시 시도"를 눌렀을 때도 key 가 바뀌어야 "불러오는 중"이 보이고, 그 전에 보낸 "더 보기" 응답도 버려집니다.
  const key = `${filterKey}#${reloadTick}`;

  useEffect(() => {
    let cancelled = false; // 화면을 떠났거나 필터가 바뀌었으면 늦게 온 응답을 버립니다
    fetchPage(null).then(
      (page) => !cancelled && setList(firstPage(key, page)),
      (e) => !cancelled && setList(failedFirstPage<T>(key, errorMessage(e))),
    );
    return () => {
      cancelled = true;
    };
  }, [key, fetchPage]);

  // 지금 key 에 대한 목록만 보여 줍니다. 필터가 막 바뀌어 아직 안 왔으면 null(= 불러오는 중)
  const current = list !== null && list.key === key ? list : null;

  /** "더 보기": next_cursor 로 다음 묶음을 받아 뒤에 붙입니다. */
  // next_cursor 를 서버에 돌려보내 다음 묶음을 받습니다. moreBusy 는 단추를 두 번 눌러 같은 묶음을 두 번 받는 것을 막습니다.
  async function loadMore() {
    if (!current || current.nextCursor === null || moreBusy) return;
    const requestKey = current.key; // 응답이 늦게 와서 그사이 필터가 바뀌었다면 appendPage 가 버립니다
    setMoreBusy(true);
    try {
      const page = await fetchPage(current.nextCursor);
      // "이전 값(prev)을 받아 새 값을 돌려주는" 형태입니다. 응답을 기다리는 동안 목록이 바뀌었어도 최신 목록에 이어 붙이기 위해서입니다.
      setList((prev) => appendPage(prev, requestKey, page));
    } catch (e) {
      setList((prev) => withError(prev, requestKey, errorMessage(e)));
    } finally {
      setMoreBusy(false);
    }
  }

  return {
    /** null 이면 첫 묶음을 불러오는 중 */
    list: current,
    /** "더 보기" 버튼을 보일지(다음 묶음이 남았는지) */
    hasMore: current !== null && current.nextCursor !== null,
    moreBusy,
    loadMore,
    reload: () => setReloadTick((n) => n + 1),
    /** 한 줄 빼기(찜 해제 · 일정 삭제 뒤) */
    remove: (id: T["id"]) => setList((prev) => removeItem(prev, id)),
    /** 한 줄만 서버 응답 값으로 바꾸기(정지 · 숨김 · 수정 뒤) */
    replace: (item: T) => setList((prev) => replaceItem(prev, item)),
    /** 새로 만든 줄을 맨 앞에 넣기(여행지 추가 뒤) */
    prepend: (item: T) => setList((prev) => prependItem(prev, item)),
  };
}

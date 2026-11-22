"use client";

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

type WithId = { id: number | string };

/**
 * filterKey: 필터를 글자로 만든 값. 바뀌면 커서를 버리고 처음부터 다시 받습니다.
 * fetchPage: cursor(처음에는 null)를 받아 한 묶음을 돌려주는 함수. useCallback 으로 감싸서 넘겨 주세요
 *            (함수가 바뀌면 다시 불러옵니다).
 */
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
  async function loadMore() {
    if (!current || current.nextCursor === null || moreBusy) return;
    const requestKey = current.key; // 응답이 늦게 와서 그사이 필터가 바뀌었다면 appendPage 가 버립니다
    setMoreBusy(true);
    try {
      const page = await fetchPage(current.nextCursor);
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

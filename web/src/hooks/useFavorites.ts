"use client";

// 이 파일이 하는 일: "내 여행 > 찜한 곳" 탭의 데이터(20개씩 불러오기 · 더 보기 · 찜 해제)를 맡는 훅.
import { useCallback, useState } from "react";
import { errorMessage, getFavorites, removeFavorite } from "@/lib/api";
import { useCursorList } from "./useCursorList";

const PAGE_SIZE = 20;

export function useFavorites(token: string) {
  const fetchPage = useCallback((cursor: number | null) => getFavorites(token, { cursor, size: PAGE_SIZE }), [token]);
  const { list, hasMore, moreBusy, loadMore, reload, remove } = useCursorList("favorites", fetchPage);
  const [actionError, setActionError] = useState<string | null>(null);

  async function unfavorite(spotId: number) {
    setActionError(null);
    try {
      await removeFavorite(token, spotId);
      // 목록을 다시 받지 않고 그 줄만 뺍니다. 커서는 "마지막으로 받은 줄"이라 더 보기가 어긋나지 않습니다.
      remove(spotId);
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  // 이름을 FavoriteList 의 props 와 맞춰 두어 <FavoriteList {...favorites} /> 로 바로 넘길 수 있습니다.
  return {
    spots: list?.items ?? null,
    loading: list === null,
    // 첫 묶음 실패(빈 목록 + 오류)와 "더 보기" 실패(목록은 있음)를 화면이 구분할 수 있게 그대로 넘깁니다.
    error: list?.error ?? null,
    actionError,
    hasMore,
    moreBusy,
    onMore: loadMore,
    onRetry: reload,
    onUnfavorite: unfavorite,
  };
}

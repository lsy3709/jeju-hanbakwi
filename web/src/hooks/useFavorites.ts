"use client";

// 이 파일이 하는 일: "내 여행 > 찜한 곳" 탭의 데이터(불러오기 · 찜 해제)를 맡는 훅.
import { useCallback, useState } from "react";
import { errorMessage, getFavorites, removeFavorite } from "@/lib/api";
import { useAsync } from "./useAsync";

export function useFavorites(token: string) {
  const load = useCallback(() => getFavorites(token), [token]);
  const { data, loading, error, reload } = useAsync(load);
  const [removed, setRemoved] = useState<number[]>([]); // 방금 찜 해제한 장소 id (화면에서 바로 숨김)
  const [actionError, setActionError] = useState<string | null>(null);

  async function unfavorite(spotId: number) {
    setActionError(null);
    try {
      await removeFavorite(token, spotId);
      setRemoved((ids) => [...ids, spotId]);
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  const spots = data ? data.filter((spot) => !removed.includes(spot.id)) : null;
  // 이름을 FavoriteList 의 props 와 맞춰 두어 <FavoriteList {...favorites} /> 로 바로 넘길 수 있습니다.
  return { spots, loading, error, actionError, onRetry: reload, onUnfavorite: unfavorite };
}

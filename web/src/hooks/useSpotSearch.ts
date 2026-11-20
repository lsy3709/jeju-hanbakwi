"use client";

// 이 파일이 하는 일: 탐색 화면의 관광지 검색 상태(1쪽 불러오기 · 더 보기 · 다시 시도)를 맡는 훅.
import { useEffect, useState } from "react";
import { errorMessage, getSpots } from "@/lib/api";
import { filtersKey } from "@/lib/exploreFilters";
import { appendPage, type Result } from "@/lib/spotList";
import type { SpotsParams } from "@/lib/types";

const PAGE_SIZE = 20;

/**
 * filters 는 바뀔 때만 새 객체여야 합니다(page 에서 useMemo 로 감싸 넘겨 주세요).
 * 돌려주는 current 가 null 이면 "불러오는 중"입니다.
 */
export function useSpotSearch(filters: SpotsParams) {
  const key = filtersKey(filters); // 필터가 바뀌었는지 비교하는 용도
  const [result, setResult] = useState<Result | null>(null);
  const [reloadTick, setReloadTick] = useState(0);
  const [moreBusy, setMoreBusy] = useState(false);

  // 필터가 바뀌거나 reload 하면 1쪽부터 다시 불러옵니다.
  useEffect(() => {
    let cancelled = false;
    getSpots({ ...filters, page: 1, size: PAGE_SIZE }).then(
      (r) => !cancelled && setResult({ key, items: r.items, total: r.total, page: 1, error: null }),
      (e) => !cancelled && setResult({ key, items: [], total: 0, page: 1, error: errorMessage(e) }),
    );
    return () => {
      cancelled = true;
    };
  }, [filters, key, reloadTick]);

  // 지금 필터에 대한 결과만 보여 줍니다. 필터가 막 바뀌어 아직 안 왔으면 null(= 불러오는 중)
  const current = result !== null && result.key === key ? result : null;

  /** "더 보기": 다음 쪽을 받아 뒤에 이어 붙입니다. */
  async function loadMore() {
    if (!result) return;
    // 요청할 때의 필터를 기억해 둡니다. 응답이 늦게 와서 그사이 필터가 바뀌었다면 그 응답은 버립니다.
    const requestKey = key;
    setMoreBusy(true);
    try {
      const next = await getSpots({ ...filters, page: result.page + 1, size: PAGE_SIZE });
      setResult((prev) => appendPage(prev, requestKey, next));
    } catch (e) {
      setResult((prev) => (prev && prev.key === requestKey ? { ...prev, error: errorMessage(e) } : prev));
    } finally {
      setMoreBusy(false);
    }
  }

  return { current, loadMore, moreBusy, reload: () => setReloadTick((n) => n + 1) };
}

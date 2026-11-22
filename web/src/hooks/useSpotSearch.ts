"use client";

// 이 파일이 하는 일: 탐색 화면의 관광지 검색 상태(첫 묶음 · 더 보기 · 다시 시도)를 맡는 훅.
// 커서로 이어 받는 일은 공통 훅(useCursorList)이 하고, 여기서는 "필터로 /spots 를 부르는 법"만 정합니다.
import { useCallback } from "react";
import { getSpots } from "@/lib/api";
import { filtersKey } from "@/lib/exploreFilters";
import type { SpotsParams } from "@/lib/types";
import { useCursorList } from "./useCursorList";

const PAGE_SIZE = 20;

/**
 * filters 는 바뀔 때만 새 객체여야 합니다(page 에서 useMemo 로 감싸 넘겨 주세요).
 * 돌려주는 list 가 null 이면 "불러오는 중"입니다.
 */
export function useSpotSearch(filters: SpotsParams) {
  const fetchPage = useCallback(
    // 필터는 이어지는 요청에도 똑같이 붙이고, cursor 만 바꿉니다.
    (cursor: number | null) => getSpots({ ...filters, cursor, size: PAGE_SIZE }),
    [filters],
  );
  return useCursorList(filtersKey(filters), fetchPage);
}

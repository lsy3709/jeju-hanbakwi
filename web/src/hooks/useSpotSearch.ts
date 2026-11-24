"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
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

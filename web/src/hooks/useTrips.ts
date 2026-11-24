"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: "내 여행 > 저장한 일정" 탭의 데이터(20개씩 불러오기 · 더 보기 · 삭제)를 맡는 훅.
import { useCallback, useState } from "react";
import { deleteTrip, errorMessage, getTrips } from "@/lib/api";
import { useCursorList } from "./useCursorList";

const PAGE_SIZE = 20;

export function useTrips(token: string) {
  const fetchPage = useCallback((cursor: number | null) => getTrips(token, { cursor, size: PAGE_SIZE }), [token]);
  const { list, hasMore, moreBusy, loadMore, reload, remove } = useCursorList("trips", fetchPage);
  const [actionError, setActionError] = useState<string | null>(null);

  // 서버에서 일정을 지운 뒤 화면 목록에서도 뺍니다.
  async function removeTrip(id: number) {
    setActionError(null);
    try {
      await deleteTrip(token, id);
      remove(id); // 목록을 다시 받지 않고 그 줄만 뺍니다(펼쳐 둔 일정·스크롤 위치가 그대로)
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  // 이름을 TripList 의 props 와 맞춰 두어 <TripList {...trips} /> 로 바로 넘길 수 있습니다.
  return {
    trips: list?.items ?? null,
    loading: list === null,
    error: list?.error ?? null,
    actionError,
    hasMore,
    moreBusy,
    onMore: loadMore,
    onRetry: reload,
    onRemove: removeTrip,
  };
}

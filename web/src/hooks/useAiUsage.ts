"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: AI 사용량(내 것 또는 전체)을 불러오는 훅. 기간(일)을 바꾸면 다시 불러옵니다.
import { useCallback, useState } from "react";
import { getAdminAiUsage, getMyAiUsage } from "@/lib/api";
import { useAsync } from "./useAsync";

// "기간" 선택 단추에 보일 일수 목록입니다.
export const USAGE_PERIODS = [7, 30, 90] as const;

/** scope: "me" = 로그인한 본인 것, "admin" = 전체(관리자만). */
export function useAiUsage(scope: "me" | "admin", token: string) {
  const [days, setDays] = useState<number>(30);
  const load = useCallback(
    () => (scope === "admin" ? getAdminAiUsage(token, days) : getMyAiUsage(token, days)),
    [scope, token, days],
  );
  // 불러오기·로딩·오류 상태는 공통 훅 useAsync 가 맡습니다. load 가 바뀌면(기간이 바뀌면) 다시 불러옵니다.
  const state = useAsync(load);
  return { days, setDays, report: state.data, loading: state.loading, error: state.error, reload: state.reload };
}

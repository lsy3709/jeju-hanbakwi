"use client";

// 이 파일이 하는 일: AI 사용량(내 것 또는 전체)을 불러오는 훅. 기간(일)을 바꾸면 다시 불러옵니다.
import { useCallback, useState } from "react";
import { getAdminAiUsage, getMyAiUsage } from "@/lib/api";
import { useAsync } from "./useAsync";

export const USAGE_PERIODS = [7, 30, 90] as const;

/** scope: "me" = 로그인한 본인 것, "admin" = 전체(관리자만). */
export function useAiUsage(scope: "me" | "admin", token: string) {
  const [days, setDays] = useState<number>(30);
  const load = useCallback(
    () => (scope === "admin" ? getAdminAiUsage(token, days) : getMyAiUsage(token, days)),
    [scope, token, days],
  );
  const state = useAsync(load);
  return { days, setDays, report: state.data, loading: state.loading, error: state.error, reload: state.reload };
}

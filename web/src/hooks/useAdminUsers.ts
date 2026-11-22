"use client";

// 이 파일이 하는 일: 관리자 화면 "사용자" 탭의 데이터(이메일 검색 · 더 보기 · 이용 정지/해제)를 맡는 훅.
import { useCallback, useState } from "react";
import { errorMessage, getAdminUsers, setUserSuspended } from "@/lib/api";
import { buildQuery } from "@/lib/format";
import type { AdminUser } from "@/lib/types";
import { useCursorList } from "./useCursorList";

const PAGE_SIZE = 20;

/** q: 이메일 검색어(빈 글자면 전체). 바뀌면 커서를 버리고 처음부터 받습니다. */
export function useAdminUsers(token: string, q: string) {
  const fetchPage = useCallback(
    (cursor: number | null) => getAdminUsers(token, { q: q || undefined, cursor, size: PAGE_SIZE }),
    [token, q],
  );
  const { list, hasMore, moreBusy, loadMore, reload, replace } = useCursorList(buildQuery({ q }), fetchPage);
  const [busyId, setBusyId] = useState<string | null>(null); // 지금 정지/해제 요청 중인 사용자
  const [actionError, setActionError] = useState<string | null>(null);

  async function setSuspended(user: AdminUser, suspended: boolean) {
    setBusyId(user.id);
    setActionError(null);
    try {
      const updated = await setUserSuspended(token, user.id, suspended);
      // 그 줄만 응답 값으로 바꿉니다(목록을 다시 받으면 스크롤이 맨 위로 갑니다).
      replace({ ...user, ...updated });
    } catch (e) {
      // 예: 자기 자신을 정지하려 하면 서버가 400 "자기 자신은 정지할 수 없습니다."
      setActionError(errorMessage(e));
    } finally {
      setBusyId(null);
    }
  }

  return { list, hasMore, moreBusy, loadMore, reload, busyId, actionError, setSuspended };
}

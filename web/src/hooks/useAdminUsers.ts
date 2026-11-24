"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: 관리자 화면 "사용자" 탭의 데이터(이메일 검색 · 더 보기 · 이용 정지/해제)를 맡는 훅.
import { useCallback, useState } from "react";
import { errorMessage, getAdminUsers, setUserSuspended } from "@/lib/api";
import { buildQuery } from "@/lib/format";
import type { AdminUser } from "@/lib/types";
import { useCursorList } from "./useCursorList";

// 한 번에 받는 개수입니다.
const PAGE_SIZE = 20;

/** q: 이메일 검색어(빈 글자면 전체). 바뀌면 커서를 버리고 처음부터 받습니다. */
export function useAdminUsers(token: string, q: string) {
  // 이메일 검색어 q 가 바뀌면 함수가 새로 만들어져 처음부터 다시 받습니다.
  const fetchPage = useCallback(
    (cursor: number | null) => getAdminUsers(token, { q: q || undefined, cursor, size: PAGE_SIZE }),
    [token, q],
  );
  const { list, hasMore, moreBusy, loadMore, reload, replace } = useCursorList(buildQuery({ q }), fetchPage);
  const [busyId, setBusyId] = useState<string | null>(null); // 지금 정지/해제 요청 중인 사용자
  const [actionError, setActionError] = useState<string | null>(null);

  // 이용 정지/해제를 서버에 요청합니다. busyId 는 어느 줄의 단추를 잠시 막을지 정하는 데 씁니다.
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

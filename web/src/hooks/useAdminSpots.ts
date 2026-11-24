"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: 관리자 화면 "여행지" 탭의 데이터(이름 검색 · 보기 필터 · 더 보기 · 숨김 · 추가 · 수정)를 맡는 훅.
import { useCallback, useState } from "react";
import { createAdminSpot, errorMessage, getAdminSpots, updateAdminSpot } from "@/lib/api";
import { buildQuery } from "@/lib/format";
import { createBody, patchBody, type SpotFormValues } from "@/lib/spotForm";
import type { AdminSpot } from "@/lib/types";
import { useCursorList } from "./useCursorList";

// 한 번에 받는 개수입니다. 더 필요하면 "더 보기"로 다음 묶음을 받습니다.
const PAGE_SIZE = 20;

/** 보기 필터: "" = 전체, "false" = 보이는 곳만, "true" = 숨긴 곳만 (서버 쿼리 hidden 과 같은 뜻) */
export type HiddenFilter = "" | "true" | "false";

// token 은 로그인 토큰, q 는 이름 검색어, hidden 은 보기 필터입니다. 돌려주는 값은 화면이 그대로 꺼내 쓰는 상태와 동작 모음입니다.
export function useAdminSpots(token: string, q: string, hidden: HiddenFilter) {
  // useCallback 은 token·q·hidden 이 바뀔 때만 함수를 새로 만들어, 공통 훅이 "필터가 바뀌었는지"를 정확히 알게 합니다.
  const fetchPage = useCallback(
    (cursor: number | null) =>
      getAdminSpots(token, {
        q: q || undefined,
        hidden: hidden === "" ? undefined : hidden === "true",
        cursor,
        size: PAGE_SIZE,
      }),
    [token, q, hidden],
  );
  const { list, hasMore, moreBusy, loadMore, reload, replace, prepend } = useCursorList(
    buildQuery({ q, hidden }),
    fetchPage,
  );
  // useState 는 화면이 기억하는 값입니다. 값을 바꾸는 함수(setBusyId)를 부르면 화면이 다시 그려집니다.
  const [busyId, setBusyId] = useState<number | null>(null); // 지금 숨김/보이기 요청 중인 여행지
  const [actionError, setActionError] = useState<string | null>(null);

  /** 숨기기 / 다시 보이기. 지우지 않고 숨기므로 언제든 되돌릴 수 있습니다. */
  async function setHidden(spot: AdminSpot, nextHidden: boolean) {
    setBusyId(spot.id);
    setActionError(null);
    try {
      // 그 줄만 응답 값으로 바꿉니다. "보이는 곳만" 필터에서 숨겨도 줄이 바로 사라지지 않아,
      // 잘못 눌렀을 때 같은 자리에서 "다시 보이기"를 누를 수 있습니다.
      replace(await updateAdminSpot(token, spot.id, { hidden: nextHidden }));
    } catch (e) {
      setActionError(errorMessage(e));
    } finally {
      setBusyId(null);
    }
  }

  /**
   * 추가(original 이 null) 또는 수정 폼을 저장합니다.
   * 실패하면 오류를 그대로 던집니다 → 폼이 받아서 폼 아래에 서버의 detail 을 보여 줍니다.
   */
  async function saveSpot(original: AdminSpot | null, values: SpotFormValues) {
    if (original === null) {
      prepend(await createAdminSpot(token, createBody(values))); // 방금 추가한 곳을 맨 위에 보여 줍니다
    } else {
      replace(await updateAdminSpot(token, original.id, patchBody(original, values)));
    }
  }

  return { list, hasMore, moreBusy, loadMore, reload, busyId, actionError, setHidden, saveSpot };
}

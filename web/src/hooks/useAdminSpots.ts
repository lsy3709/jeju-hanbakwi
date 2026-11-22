"use client";

// 이 파일이 하는 일: 관리자 화면 "여행지" 탭의 데이터(이름 검색 · 보기 필터 · 더 보기 · 숨김 · 추가 · 수정)를 맡는 훅.
import { useCallback, useState } from "react";
import { createAdminSpot, errorMessage, getAdminSpots, updateAdminSpot } from "@/lib/api";
import { buildQuery } from "@/lib/format";
import { createBody, patchBody, type SpotFormValues } from "@/lib/spotForm";
import type { AdminSpot } from "@/lib/types";
import { useCursorList } from "./useCursorList";

const PAGE_SIZE = 20;

/** 보기 필터: "" = 전체, "false" = 보이는 곳만, "true" = 숨긴 곳만 (서버 쿼리 hidden 과 같은 뜻) */
export type HiddenFilter = "" | "true" | "false";

export function useAdminSpots(token: string, q: string, hidden: HiddenFilter) {
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

"use client";

// 이 파일이 하는 일: "내 여행 > 저장한 일정" 탭의 데이터(불러오기 · 삭제)를 맡는 훅.
import { useCallback, useState } from "react";
import { deleteTrip, errorMessage, getTrips } from "@/lib/api";
import { useAsync } from "./useAsync";

export function useTrips(token: string) {
  const load = useCallback(() => getTrips(token), [token]);
  const { data, loading, error, reload } = useAsync(load);
  const [removed, setRemoved] = useState<number[]>([]);
  const [actionError, setActionError] = useState<string | null>(null);

  async function remove(id: number) {
    setActionError(null);
    try {
      await deleteTrip(token, id);
      setRemoved((ids) => [...ids, id]);
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  const trips = data ? data.filter((trip) => !removed.includes(trip.id)) : null;
  // 이름을 TripList 의 props 와 맞춰 두어 <TripList {...trips} /> 로 바로 넘길 수 있습니다.
  return { trips, loading, error, actionError, onRetry: reload, onRemove: remove };
}

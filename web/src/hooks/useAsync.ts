"use client";

// 이 파일이 하는 일: 화면이 열릴 때 데이터를 한 번 불러오고 "불러오는 중 / 오류 / 결과" 상태를 돌려주는 작은 훅.
// 주의: load 함수는 useCallback 으로 감싸 주세요(함수가 바뀔 때만 다시 불러옵니다).
import { useEffect, useState } from "react";
import { ApiError, errorMessage } from "@/lib/api";

type Result<T> = { source: unknown; tick: number; data: T | null; error: string | null; status: number | null };

export function useAsync<T>(load: () => Promise<T>) {
  const [result, setResult] = useState<Result<T> | null>(null);
  const [tick, setTick] = useState(0); // reload() 를 누를 때마다 1 씩 늘어 다시 불러옵니다

  useEffect(() => {
    let cancelled = false; // 화면을 떠났거나 load 가 바뀌었으면 늦게 온 응답을 버립니다
    load().then(
      (data) => !cancelled && setResult({ source: load, tick, data, error: null, status: null }),
      (error) => !cancelled && setResult({
          source: load,
          tick,
          data: null,
          error: errorMessage(error),
          status: error instanceof ApiError ? error.status : null, // 404 같은 HTTP 상태
        }),
    );
    return () => {
      cancelled = true;
    };
  }, [load, tick]);

  // 결과가 "지금의 load·tick" 에 대한 것이 아니면 아직 불러오는 중입니다.
  const fresh = result !== null && result.source === load && result.tick === tick;
  return {
    loading: !fresh,
    data: fresh ? result.data : null,
    error: fresh ? result.error : null,
    status: fresh ? result.status : null,
    reload: () => setTick((n) => n + 1),
  };
}

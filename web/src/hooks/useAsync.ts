"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: 화면이 열릴 때 데이터를 한 번 불러오고 "불러오는 중 / 오류 / 결과" 상태를 돌려주는 작은 훅.
// 주의: load 함수는 useCallback 으로 감싸 주세요(함수가 바뀔 때만 다시 불러옵니다).
import { useEffect, useState } from "react";
import { ApiError, errorMessage } from "@/lib/api";

// 불러온 결과에 "어떤 load, 몇 번째 reload 의 결과인지"를 함께 적어 둡니다. 옛 요청의 결과가 새 화면에 보이는 것을 막으려는 표시입니다.
type Result<T> = { source: unknown; tick: number; data: T | null; error: string | null; status: number | null };

// load 는 서버를 부르는 함수(Promise 를 돌려줌 = 나중에 결과가 오는 약속)입니다. T 는 결과 자료의 모양입니다.
export function useAsync<T>(load: () => Promise<T>) {
  const [result, setResult] = useState<Result<T> | null>(null);
  const [tick, setTick] = useState(0); // reload() 를 누를 때마다 1 씩 늘어 다시 불러옵니다

  // useEffect 는 화면이 그려진 뒤(또는 아래 [load, tick] 이 바뀐 뒤) 한 번 실행되는 부분입니다. 서버 부르기처럼 "그리는 일이 아닌 일"을 여기에 둡니다.
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
  // 화면에 내보내는 값: 결과가 지금 요청의 것일 때만 쓰고, 아니면 "불러오는 중"으로 둡니다.
  const fresh = result !== null && result.source === load && result.tick === tick;
  return {
    loading: !fresh,
    data: fresh ? result.data : null,
    error: fresh ? result.error : null,
    status: fresh ? result.status : null,
    reload: () => setTick((n) => n + 1),
  };
}

"use client";

// 이 파일이 하는 일: "브라우저에서 화면이 서버 화면에 이어 붙었는지(하이드레이션이 끝났는지)"를 알려 주는 훅.
// 왜: sessionStorage 같은 브라우저 전용 값을 서버가 만든 첫 화면과 다르게 그리면 하이드레이션 오류가 납니다.
//     서버·첫 렌더에서는 false, 브라우저에서 이어 붙은 뒤에는 true 를 돌려주므로, true 가 된 다음에 읽으면 안전합니다.
//     (useEffect 안에서 setState 하는 방법은 react-hooks/set-state-in-effect 규칙에 걸려서 useSyncExternalStore 를 씁니다)
import { useSyncExternalStore } from "react";

const subscribe = () => () => {}; // 바뀔 일이 없는 값이라 구독할 것이 없습니다

export function useHydrated(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => true,
    () => false,
  );
}

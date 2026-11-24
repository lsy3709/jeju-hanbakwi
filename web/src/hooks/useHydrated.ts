"use client";

// "use client" 는 이 파일이 브라우저에서 도는 코드라는 표시입니다. useState·useEffect 같은 React 훅은 브라우저에서만 쓸 수 있습니다.
// 훅(use… 로 시작하는 함수) = 화면의 상태와 불러오기를 화면 파일에서 떼어 낸 것입니다. 층: 화면(app/) → 훅 → lib/api.ts.
// 이 파일이 하는 일: "브라우저에서 화면이 서버 화면에 이어 붙었는지(하이드레이션이 끝났는지)"를 알려 주는 훅.
// 왜: sessionStorage 같은 브라우저 전용 값을 서버가 만든 첫 화면과 다르게 그리면 하이드레이션 오류가 납니다.
//     서버·첫 렌더에서는 false, 브라우저에서 이어 붙은 뒤에는 true 를 돌려주므로, true 가 된 다음에 읽으면 안전합니다.
//     (useEffect 안에서 setState 하는 방법은 react-hooks/set-state-in-effect 규칙에 걸려서 useSyncExternalStore 를 씁니다)
import { useSyncExternalStore } from "react";

// 낱말 풀이: 하이드레이션 = 서버가 만든 HTML 에 브라우저의 React 가 이어 붙어 동작하게 되는 일입니다.
const subscribe = () => () => {}; // 바뀔 일이 없는 값이라 구독할 것이 없습니다

export function useHydrated(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => true,
    () => false,
  );
}

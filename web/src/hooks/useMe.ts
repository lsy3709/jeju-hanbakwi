"use client";

// 이 파일이 하는 일: 로그인한 사용자의 서버 쪽 정보(/me — 관리자인지 · 이용 정지인지)를 불러오는 훅. AuthProvider 가 씁니다.
import { useCallback, useEffect, useState } from "react";
import { errorMessage, getMe } from "@/lib/api";
import type { Me } from "@/lib/types";

type State = { userId: string; me: Me | null; error: string | null };

/**
 * token: Supabase 액세스 토큰, userId: 로그인한 사용자 id(로그아웃이면 둘 다 null).
 * 왜 userId 를 따로 받나: 토큰은 한 시간쯤마다 새로 바뀝니다. 그때마다 me 를 null 로 비우면
 * 관리자 메뉴가 깜빡이고 내 여행 화면이 다시 그려지므로, 같은 사람이면 새 값이 올 때까지 앞의 값을 그대로 씁니다.
 */
export function useMe(token: string | null, userId: string | null) {
  const [state, setState] = useState<State | null>(null);
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (!token || !userId) return;
    let cancelled = false;
    getMe(token).then(
      (me) => !cancelled && setState({ userId, me, error: null }),
      (e) =>
        !cancelled &&
        // 토큰을 갱신하다 잠깐 실패한 것이면 앞에서 받은 값을 지킵니다.
        setState((prev) => (prev?.userId === userId && prev.me ? prev : { userId, me: null, error: errorMessage(e) })),
    );
    return () => {
      cancelled = true;
    };
  }, [token, userId, tick]);

  // AuthProvider 가 이 함수를 context 값에 넣으므로, 매번 새 함수가 되지 않게 useCallback 으로 고정합니다.
  const reload = useCallback(() => setTick((n) => n + 1), []);

  // 다른 사람으로 바뀌었거나 로그아웃했으면 앞사람의 값은 쓰지 않습니다.
  const current = userId && state?.userId === userId ? state : null;
  return {
    me: current?.me ?? null,
    /** 로그인했는데 아직 /me 응답이 없으면 true */
    loading: Boolean(token && userId) && current === null,
    error: current?.error ?? null,
    reload,
  };
}

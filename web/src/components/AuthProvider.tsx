"use client";

// 이 파일이 하는 일: 로그인 상태(토큰·이메일)를 앱 전체에 나눠 주고 구글 로그인·로그아웃을 실행하는 React context 입니다.
// 보여 주기만 하는 컴포넌트가 아니라 "기능이 본질"인 예외입니다(Supabase 호출은 로그인에만 씁니다).
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { Session } from "@supabase/supabase-js";
import { getSupabase, supabaseConfigured } from "@/lib/supabase";

type AuthState = {
  /** 세션을 아직 확인하는 중이면 true */
  loading: boolean;
  /** Supabase 설정 값이 있는지(없으면 로그인 버튼 대신 안내를 보여 줍니다) */
  configured: boolean;
  email: string | null;
  /** API 요청의 Authorization: Bearer 에 넣을 토큰. 로그인 전이면 null */
  token: string | null;
  /** next: 로그인을 마치고 돌아올 경로(기본 "/my"). Supabase 대시보드의 Redirect URLs 에도 등록돼 있어야 합니다. */
  signInWithGoogle: (next?: string) => Promise<void>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  // 설정이 없으면 확인할 세션도 없으므로 처음부터 loading=false
  const [loading, setLoading] = useState(supabaseConfigured);

  useEffect(() => {
    const supabase = getSupabase();
    if (!supabase) return;

    // 처음 열 때의 세션(구글에서 돌아온 직후 주소의 토큰도 여기서 처리됩니다)
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });
    // 로그인·로그아웃·토큰 갱신이 일어날 때마다 알려 줍니다.
    const { data } = supabase.auth.onAuthStateChange((_event, next) => setSession(next));
    return () => data.subscription.unsubscribe();
  }, []);

  const signInWithGoogle = useCallback(async (next: string = "/my") => {
    const supabase = getSupabase();
    if (!supabase) return;
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: window.location.origin + next },
    });
  }, []);

  const signOut = useCallback(async () => {
    await getSupabase()?.auth.signOut();
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      loading,
      configured: supabaseConfigured,
      email: session?.user.email ?? null,
      token: session?.access_token ?? null,
      signInWithGoogle,
      signOut,
    }),
    [loading, session, signInWithGoogle, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth 는 AuthProvider 안에서만 쓸 수 있어요.");
  return value;
}

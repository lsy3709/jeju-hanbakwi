"use client";

// 이 파일이 하는 일: 로그인 상태(토큰·이메일)를 앱 전체에 나눠 주고 구글 로그인·로그아웃을 실행하는 React context 입니다.
// 보여 주기만 하는 컴포넌트가 아니라 "기능이 본질"인 예외입니다(Supabase 호출은 로그인에만 씁니다).
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { Session } from "@supabase/supabase-js";
import { useMe } from "@/hooks/useMe";
import { getSupabase, supabaseConfigured } from "@/lib/supabase";
import type { Me } from "@/lib/types";

type AuthState = {
  /** 세션을 아직 확인하는 중이면 true */
  loading: boolean;
  /** Supabase 설정 값이 있는지(없으면 로그인 버튼 대신 안내를 보여 줍니다) */
  configured: boolean;
  email: string | null;
  /** API 요청의 Authorization: Bearer 에 넣을 토큰. 로그인 전이면 null */
  token: string | null;
  /** 서버가 알려 준 내 정보(/me: 관리자인지 · 이용 정지인지). 로그인 전이거나 아직 못 받았으면 null */
  me: Me | null;
  /** 로그인했는데 /me 를 아직 기다리는 중이면 true */
  meLoading: boolean;
  /** /me 를 불러오지 못했을 때의 문구 */
  meError: string | null;
  reloadMe: () => void;
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
    const supabase = getSupabase();
    if (!supabase) return;
    const { error } = await supabase.auth.signOut();
    // Supabase 에 닿지 못하면(네트워크 끊김 등) 로그인 정보가 이 기기에 그대로 남습니다.
    // 그때는 이 기기에 저장된 것만이라도 지워, 로그아웃을 눌렀는데 계속 로그인돼 있는 일이 없게 합니다.
    if (error) await supabase.auth.signOut({ scope: "local" });
  }, []);

  const token = session?.access_token ?? null;
  // 관리자 여부·정지 여부는 Supabase 가 아니라 우리 서버(/me)가 정합니다. 그래서 로그인 뒤 한 번 더 물어봅니다.
  const { me, loading: meLoading, error: meError, reload: reloadMe } = useMe(token, session?.user.id ?? null);

  const value = useMemo<AuthState>(
    () => ({
      loading,
      configured: supabaseConfigured,
      email: session?.user.email ?? null,
      token,
      me,
      meLoading,
      meError,
      reloadMe,
      signInWithGoogle,
      signOut,
    }),
    [loading, session, token, me, meLoading, meError, reloadMe, signInWithGoogle, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth 는 AuthProvider 안에서만 쓸 수 있어요.");
  return value;
}

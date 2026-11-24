// Supabase 는 "로그인"에만 씁니다. 데이터는 전부 API 서버를 거칩니다.
// 이 파일이 하는 일: Supabase(로그인 서비스)에 연결하는 도구를 한 번만 만들어 돌려줍니다. AuthProvider.tsx 가 로그인 상태를 알아낼 때 부릅니다.
// 주소와 공개 키는 NEXT_PUBLIC_ 환경변수에서 읽습니다. 이 키(anon)는 브라우저에 공개돼도 되는 키입니다.
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

/** 설정 값이 둘 다 있으면 true. 없으면 로그인 기능만 꺼지고 앱은 그대로 동작합니다. */
export const supabaseConfigured = Boolean(url && anonKey);

// 한 번 만든 연결을 다시 쓰려고 담아 둡니다(여러 번 만들면 로그인 상태가 어긋날 수 있습니다).
let client: SupabaseClient | null = null;

/** 브라우저에서만 호출하세요. 설정이 비어 있으면 null. */
export function getSupabase(): SupabaseClient | null {
  if (!url || !anonKey) return null;
  if (!client) client = createClient(url, anonKey);
  return client;
}

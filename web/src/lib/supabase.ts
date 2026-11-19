// Supabase 는 "로그인"에만 씁니다. 데이터는 전부 API 서버를 거칩니다.
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

/** 설정 값이 둘 다 있으면 true. 없으면 로그인 기능만 꺼지고 앱은 그대로 동작합니다. */
export const supabaseConfigured = Boolean(url && anonKey);

let client: SupabaseClient | null = null;

/** 브라우저에서만 호출하세요. 설정이 비어 있으면 null. */
export function getSupabase(): SupabaseClient | null {
  if (!url || !anonKey) return null;
  if (!client) client = createClient(url, anonKey);
  return client;
}

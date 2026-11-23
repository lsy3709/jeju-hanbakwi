-- 004_ai_usage.sql — AI 사용량 기록
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 실행합니다. (여러 번 실행해도 안전)
-- 001 ~ 003 을 먼저 실행한 뒤에 실행합니다.

-- AI 일정 짜기(POST /agent/plan)가 한 번 불릴 때마다 서버가 한 줄씩 적습니다.
-- 요청 글 · 일정 내용 · AI 키는 적지 않습니다. "누가 · 언제 · 어떤 방식으로 · 얼마나"만 적습니다.
create table if not exists public.ai_usage (
  id            bigint generated always as identity primary key,
  user_id       uuid references auth.users (id) on delete set null,   -- 로그인하지 않은 요청은 비어 있음
  mode          text not null check (mode in ('ai', 'rule')),          -- ai: AI 가 짬 / rule: 규칙으로 짬
  key_source    text not null check (key_source in ('user', 'server', 'none')),  -- 내 키 / 서버 키 / AI 를 쓰지 않음
  days          int  not null,                                         -- 며칠 일정을 요청했는지
  duration_ms   int  not null default 0,                               -- 걸린 시간
  ai_calls      int  not null default 0,                               -- AI 를 부른 횟수(도구를 부르며 오간 왕복 수)
  tokens_in     int  not null default 0,                               -- AI 에게 보낸 토큰(모든 왕복의 합)
  tokens_out    int  not null default 0,                               -- AI 가 쓴 토큰(생각 포함)
  tokens_total  int  not null default 0,
  created_at    timestamptz not null default now()
);

-- "최근 며칠" / "이 사람의 최근 며칠"을 빨리 찾게 합니다.
create index if not exists ai_usage_created_idx on public.ai_usage (created_at desc);
create index if not exists ai_usage_user_idx    on public.ai_usage (user_id, created_at desc);

-- 화면은 이 표를 직접 읽지 못합니다. 서버(service_role)만 읽고 씁니다.
alter table public.ai_usage enable row level security;
revoke all on public.ai_usage from anon, authenticated;
grant  all on public.ai_usage to service_role;

-- PostgREST(Supabase 의 API)가 새 표를 바로 알아보게 합니다.
notify pgrst, 'reload schema';

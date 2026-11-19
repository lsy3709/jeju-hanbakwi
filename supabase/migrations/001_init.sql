-- 001_init.sql — 제주 한 바퀴 기본 테이블
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 실행합니다. (여러 번 실행해도 안전)

-- 1) 관광지 ---------------------------------------------------------------
create table if not exists public.spots (
  id          bigint generated always as identity primary key,
  source      text not null default 'sample',        -- 어디서 온 데이터인가 (sample / tourapi)
  source_id   text not null,                          -- 원본의 고유 번호
  title       text not null,
  category    text not null,                          -- 관광지 · 문화시설 · 축제 · 레포츠 · 쇼핑 · 음식점
  area        text not null,                          -- 제주시 · 서귀포시 · 동부 · 서부
  address     text not null default '',
  lat         double precision,
  lng         double precision,
  image_url   text,
  overview    text not null default '',               -- 원본 소개 글
  one_liner   text not null default '',               -- 우리가 붙인 한 줄 소개
  theme_tags  text[] not null default '{}',           -- 우리가 붙인 테마 태그
  indoor      boolean not null default false,         -- 우리가 붙인 실내/실외
  updated_at  timestamptz not null default now(),
  unique (source, source_id)                          -- 같은 원본을 다시 받아도 한 줄만 유지
);

create index if not exists spots_theme_tags_idx on public.spots using gin (theme_tags);
create index if not exists spots_area_idx on public.spots (area);

-- 2) 찜 -------------------------------------------------------------------
create table if not exists public.favorites (
  user_id     uuid   not null references auth.users (id) on delete cascade,
  spot_id     bigint not null references public.spots (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, spot_id)                      -- 같은 곳을 두 번 찜할 수 없음
);

-- 3) 저장한 일정 ------------------------------------------------------------
create table if not exists public.trips (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null,
  itinerary   jsonb not null,
  created_at  timestamptz not null default now()
);

create index if not exists trips_user_idx on public.trips (user_id, created_at desc);

-- 4) 보안 ------------------------------------------------------------------
-- 행 단위 보안(RLS)을 켜고 정책을 하나도 만들지 않습니다.
-- => 웹·앱이 가진 공개 키(anon)로는 이 테이블을 읽을 수도 쓸 수도 없습니다.
-- => 비밀 키(service_role)를 가진 우리 서버(FastAPI)만 접근합니다.
alter table public.spots     enable row level security;
alter table public.favorites enable row level security;
alter table public.trips     enable row level security;

revoke all on public.spots, public.favorites, public.trips from anon, authenticated;
grant  all on public.spots, public.favorites, public.trips to service_role;

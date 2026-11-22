-- 003_admin.sql — 관리자 화면과 커서 페이징에 필요한 것
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 실행합니다. (여러 번 실행해도 안전)
-- 001_init.sql, 002_image_credit.sql 을 먼저 실행한 뒤에 실행합니다.

-- 1) 여행지 숨김 ------------------------------------------------------------
-- 관리자가 지우는 대신 숨깁니다. 숨긴 곳은 목록·상세·일정 추천에 나오지 않습니다.
-- (지우면 그곳을 찜한 기록과 저장한 일정이 어긋나므로, 되돌릴 수 있는 숨김을 씁니다)
alter table public.spots add column if not exists hidden boolean not null default false;

-- 2) 찜에 번호 붙이기 --------------------------------------------------------
-- 커서 페이징은 "마지막으로 받은 줄의 번호보다 작은 것부터"로 다음 묶음을 찾습니다.
-- 찜에는 번호가 없었으므로 하나 붙입니다. 번호가 클수록 나중에 찜한 것입니다.
alter table public.favorites add column if not exists id bigint generated always as identity;
create unique index if not exists favorites_id_idx on public.favorites (id);

-- "이 사람의 찜을 번호 큰 순으로" / "이 사람의 일정을 번호 큰 순으로"를 빨리 찾게 합니다.
create index if not exists favorites_user_id_idx on public.favorites (user_id, id desc);
create index if not exists trips_user_id_idx     on public.trips     (user_id, id desc);

-- 3) 사용자 목록 -------------------------------------------------------------
-- 로그인 정보(auth.users)는 Supabase 가 관리하는 곳이라 우리 서버가 목록으로 넘겨 보기 어렵습니다.
-- 그래서 가입할 때마다 한 줄씩 따라 적는 표를 둡니다. 이용 정지 여부도 여기에 적습니다.
create table if not exists public.profiles (
  no          bigint generated always as identity primary key,   -- 가입 순서 번호(커서로 씀)
  id          uuid not null unique references auth.users (id) on delete cascade,
  email       text,
  suspended   boolean not null default false,                    -- true 면 찜·일정 저장을 못 함
  created_at  timestamptz not null default now()
);

-- 새로 가입하면 profiles 에 한 줄을 자동으로 넣습니다.
-- security definer: 가입 처리를 하는 쪽(auth)이 public.profiles 에 쓸 수 있게 함수 주인의 권한으로 실행합니다.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 이 파일을 실행하기 전에 이미 가입한 사람도 넣어 줍니다.
insert into public.profiles (id, email)
select u.id, u.email from auth.users u
on conflict (id) do nothing;

-- 4) 관리자 화면용 보기(view) -------------------------------------------------
-- 사용자마다 찜 수·일정 수를 따로 물으면 20명에 40번을 묻게 됩니다. 한 번에 세어 주는 보기를 둡니다.
-- security_invoker: 보기를 부른 쪽의 권한으로 아래 표들을 읽습니다(공개 키로는 읽히지 않게).
create or replace view public.admin_users
with (security_invoker = true) as
select
  p.no,
  p.id,
  p.email,
  p.suspended,
  p.created_at,
  (select count(*) from public.favorites f where f.user_id = p.id) as favorite_count,
  (select count(*) from public.trips     t where t.user_id = p.id) as trip_count
from public.profiles p;

-- 5) 보안 ------------------------------------------------------------------
-- 001 과 같은 원칙: 공개 키(anon)로는 읽을 수도 쓸 수도 없고, 우리 서버(service_role)만 접근합니다.
-- 보기(view)는 표와 따로 권한을 가지므로 빠뜨리지 않고 막습니다.
alter table public.profiles enable row level security;

revoke all on public.profiles, public.admin_users from anon, authenticated;
grant  all on public.profiles to service_role;
grant  select on public.admin_users to service_role;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- 표 모양이 바뀐 것을 API 쪽에 알립니다. (Supabase 는 스스로 알아채지만, 로컬 Docker 에서는 필요합니다)
notify pgrst, 'reload schema';

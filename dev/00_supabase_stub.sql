-- 로컬 Docker 전용: 진짜 Supabase 에는 이미 있는 것들을 흉내 냅니다.
-- (Supabase 에서는 실행하지 마세요.)
do $$
begin
  if not exists (select from pg_roles where rolname = 'anon')          then create role anon nologin; end if;
  if not exists (select from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  if not exists (select from pg_roles where rolname = 'service_role')  then create role service_role nologin bypassrls; end if;
end $$;

grant usage on schema public to anon, authenticated, service_role;

create schema if not exists auth;
create table if not exists auth.users (
  id    uuid primary key,
  email text
);

-- 로컬 확인용 가짜 사용자 한 명
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-000000000001', 'local-tester@example.com')
on conflict do nothing;

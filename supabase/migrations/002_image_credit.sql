-- 002_image_credit.sql — 사진 출처 칸 추가
-- Supabase 대시보드 > SQL Editor 에서 001 다음에 실행합니다. (여러 번 실행해도 안전)
--
-- 공개 라이선스(CC BY 등) 사진은 "누가 찍었고 어떤 라이선스인지"를 함께 보여 줘야 쓸 수 있습니다.
-- 그래서 사진 주소 옆에 출처를 같이 저장합니다.

alter table public.spots add column if not exists image_credit     text;  -- 예: "홍길동 · CC BY-SA 4.0"
alter table public.spots add column if not exists image_source_url text;  -- 사진 원본 설명 쪽 주소

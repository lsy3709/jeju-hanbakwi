# 제주 한 바퀴 — 웹 (Next.js)

날씨와 취향에 맞는 제주 관광지를 찾고, AI가 일자별 여행 일정을 짜 주는 웹 화면입니다.

## 실행 방법

```bash
npm install
cp .env.local.example .env.local   # Windows PowerShell 은 copy 를 쓰세요
npm run dev
```

브라우저에서 http://localhost:3000 을 엽니다.

## 환경변수 (`.env.local`)

- `NEXT_PUBLIC_API_URL`: 서버(FastAPI) 주소. 기본값은 `http://localhost:8000` 입니다.
- `NEXT_PUBLIC_SUPABASE_URL`: Supabase 프로젝트 주소. 로그인에만 씁니다. 비워 두면 로그인만 꺼집니다.
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Supabase 공개(anon) 키. 로그인에만 씁니다.

## 검사 명령

```bash
npm run lint          # ESLint 검사
npx tsc --noEmit      # 타입 검사
npm test              # 단위 테스트 (vitest)
npm run build         # 배포용 빌드
```

## 폴더 안내 (`src/`)

- `app/`: 화면 경로입니다. `page.tsx`(홈), `explore/`(탐색), `planner/`(AI 플래너), `my/`(내 여행), `spots/[id]/`(관광지 상세). `layout.tsx` 는 공통 틀, `globals.css` 는 색·글꼴 토큰입니다.
- `components/`: 화면 조각(헤더, 관광지 카드, 지도, 날씨 배너, 로그인 패널 등)입니다.
- `lib/`: 데이터와 설정입니다. `api.ts`(서버 호출), `supabase.ts`(로그인), `brand.ts`(서비스 이름·문구), `types.ts`(서버 응답 모양), `format.ts`(검색 주소 만들기 등 순수 함수), `useAsync.ts`(불러오기 상태 훅).

## 브랜드를 바꿀 때 고칠 파일

- `src/lib/brand.ts`: 서비스 이름, 한 줄 소개(tagline), 설명 문구
- `src/app/globals.css`: 색상과 모서리 등 디자인 토큰 (`@theme` 안의 값)

전체 설명은 저장소 루트 README 참고.

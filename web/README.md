# 제주 한 바퀴 — 웹 (Next.js)

날씨와 취향에 맞는 제주 관광지를 찾아보는 웹 화면입니다.

## 실행 방법

```bash
npm install
cp .env.local.example .env.local   # Windows PowerShell 은 copy 를 쓰세요
npm run dev
```

브라우저에서 http://localhost:3000 을 엽니다.

## 환경변수 (`.env.local`)

- `NEXT_PUBLIC_API_URL`: 서버(FastAPI) 주소. 기본값은 `http://localhost:8000` 입니다.

## 검사 명령

```bash
npm run lint          # ESLint 검사
npx tsc --noEmit      # 타입 검사
npm test              # 단위 테스트 (vitest)
npm run build         # 배포용 빌드
```

## 폴더 안내 (`src/`)

위에서 아래로 갈수록 "화면과 멀어지는" 구조입니다. 각 폴더는 한 가지 일만 합니다.

| 폴더 | 역할 | 지켜야 할 것 |
|---|---|---|
| `app/` | 화면 경로. `page.tsx` 는 **조립만** 합니다(홈 `/`, `explore/`, `spots/[id]/`). `layout.tsx` 는 공통 틀, `globals.css` 는 색·글꼴 토큰 | 상태·불러오기 로직은 `hooks/` 로 뺍니다 |
| `components/` | **보여 주기만** 하는 화면 조각(헤더, 카드, 지도, 목록 …) | 서버를 부르지 않습니다. |
| `hooks/` | 화면 상태와 데이터 불러오기를 담은 커스텀 훅 (`useAsync`, `useSpotSearch`, `useHydrated`) | 화면(JSX)을 그리지 않습니다 |
| `lib/` | React 와 무관한 순수 코드 (`api.ts` 서버 호출, `types.ts` 응답 모양, `format.ts` 글자 만들기, `exploreFilters.ts` 탐색 주소 ↔ 필터, `spotList.ts`, `brand.ts` 이름·문구) | 테스트(`*.test.ts`)를 곁에 둡니다 |

**서버와 통하는 곳은 `lib/api.ts` 하나뿐입니다.** 화면은 `fetch` 를 직접 부르지 않고 `api.ts` 의 함수만 씁니다.

## 이걸 바꾸려면 어디를 고치나

| 바꾸고 싶은 것 | 고칠 곳 |
|---|---|
| 브랜드 색 · 모서리 · 글꼴 | `src/app/globals.css` 의 `@theme` 값 (한 곳에서만 정의) |
| 서비스 이름 · 한 줄 소개 · 설명 문구 | `src/lib/brand.ts` 의 `BRAND` |
| 메뉴(상단 메뉴 · 하단 탭) | `src/lib/brand.ts` 의 `NAV_ITEMS` |
| 화면 문구(버튼 글자, 안내 문장) | 그 글자가 보이는 `components/*.tsx` 또는 `app/**/page.tsx`. 글자로 찾으면 바로 나옵니다 |
| 서버 주소 | `.env.local` 의 `NEXT_PUBLIC_API_URL` (코드는 고치지 않습니다. 배포 환경에서는 호스팅 서비스의 환경변수) |
| 새 화면(경로) 추가 | `src/app/<경로>/page.tsx` 를 만들고(조립만), 메뉴에 넣으려면 `NAV_ITEMS` 에 한 줄 추가. 상태가 필요하면 `hooks/` 에 훅을 만들어 씁니다 |
| 새 API 함수 추가 | 먼저 `docs/api.md` 를 고치고 → `lib/types.ts` 에 응답 모양 → `lib/api.ts` 에 함수 한 줄 → 화면은 훅을 거쳐 그 함수를 씁니다 |

전체 설명은 저장소 루트 README 참고.

# 제주 한 바퀴 — 웹 (Next.js)

제주 관광지를 찾아보는 웹 화면입니다. 지금은 임시 데이터(`src/lib/sample-spots.json`, 12건)로 동작하며, 서버와는 3일차에 연결합니다.

## 실행 방법

```bash
npm install
npm run dev
```

브라우저에서 http://localhost:3000 을 엽니다.

## 검사 명령

```bash
npm run lint          # ESLint 검사
npx tsc --noEmit      # 타입 검사
npm test              # 단위 테스트 (vitest)
npm run build         # 배포용 빌드
```

## 폴더 안내 (`src/`)

| 폴더 | 역할 | 지켜야 할 것 |
|---|---|---|
| `app/` | 화면 경로. `page.tsx` 는 **조립만** 합니다(홈 `/`, `explore/`, `spots/[id]/`). `layout.tsx` 는 공통 틀, `globals.css` 는 색·글꼴 토큰 | 계산은 `lib/` 의 함수로 뺍니다 |
| `components/` | **보여 주기만** 하는 화면 조각(헤더, 카드, 검색바, 테마 칩 …) | 데이터를 직접 찾지 않고 받은 것만 그립니다 |
| `lib/` | React 와 무관한 순수 코드. `sample-spots.json`(임시 관광지 12건), `spots.ts`(임시 데이터에서 찾고 거르는 함수), `types.ts`(관광지 모양), `format.ts`(검색 주소 만들기 등), `brand.ts`(이름·문구) | 테스트(`*.test.ts`)를 곁에 둡니다 |

3일차에 `lib/api.ts`(서버 호출)와 `hooks/`(불러오기 상태)가 생기고, 화면이 임시 데이터 대신 서버에서 데이터를 받습니다.

## 이걸 바꾸려면 어디를 고치나

| 바꾸고 싶은 것 | 고칠 곳 |
|---|---|
| 브랜드 색 · 모서리 · 글꼴 | `src/app/globals.css` 의 `@theme` 값 (한 곳에서만 정의) |
| 서비스 이름 · 한 줄 소개 · 설명 문구 | `src/lib/brand.ts` 의 `BRAND` |
| 메뉴(상단 메뉴 · 하단 탭) | `src/lib/brand.ts` 의 `NAV_ITEMS` |
| 화면 문구(버튼 글자, 안내 문장) | 그 글자가 보이는 `components/*.tsx` 또는 `app/**/page.tsx`. 글자로 찾으면 바로 나옵니다 |
| 새 화면(경로) 추가 | `src/app/<경로>/page.tsx` 를 만들고(조립만), 메뉴에 넣으려면 `NAV_ITEMS` 에 한 줄 추가 |
| 임시 관광지 바꾸기 | `src/lib/sample-spots.json` (모양은 `lib/types.ts` 의 `Spot`) |

전체 설명은 저장소 루트 README 참고.

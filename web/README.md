# 제주 한 바퀴 — 웹 (Next.js)

1일차에 만든 첫 화면 한 장(`/`)입니다. 서비스 이름, 인사 문구, 검색창, 테마 칩이 있고, 검색창과 칩은 모양만 있어 눌러도 이동하지 않습니다.

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
npm test              # 단위 테스트 (vitest, 아직 테스트 파일이 없어도 통과)
npm run build         # 배포용 빌드
```

## 폴더 안내 (`src/`)

- `app/`: 화면 경로입니다. `page.tsx`(첫 화면), `layout.tsx`(공통 틀), `globals.css`(색·글꼴 토큰).
- `components/`: 화면 조각(검색바, 테마 칩)과 칩 모양(`ui.ts`)입니다.
- `lib/`: `brand.ts`(서비스 이름·문구)

## 브랜드를 바꿀 때 고칠 파일

- `src/lib/brand.ts`: 서비스 이름, 한 줄 소개(tagline), 설명 문구
- `src/app/globals.css`: 색상과 모서리 등 디자인 토큰 (`@theme` 안의 값)

전체 설명은 저장소 루트 README 참고.

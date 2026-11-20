# 제주 한 바퀴

> **이 브랜치는 1일차 수업이 끝난 상태입니다.** 오늘까지 만든 것: Next.js 첫 화면 한 장과 첫 배포 / 다음 날 만드는 것: 디자인 토큰을 입힌 홈·탐색·상세 화면(임시 데이터), DB 테이블, 서버 첫 API / 완성본은 main 브랜치.

취향에 맞는 제주 관광지를 찾아보는 여행 서비스. 수업에서 한 걸음씩 따라 만들어 보는 샘플입니다.

| 폴더 | 내용 |
|---|---|
| `web/` | 웹 화면 (Next.js, Tailwind) |
| `docs/` | [화면·디자인 기준](docs/design.md) 등 문서 |

## 처음 실행하기

준비물: Node.js 22 이상. 폴더는 `C:\work\jeju-hanbakwi` 처럼 **영문 경로**에 두세요.

```bash
cd web
npm install
npm run dev
```

http://localhost:3000 에서 첫 화면을 확인합니다.

## 첫 배포 (GitHub → Vercel)

1. 이 폴더를 GitHub 저장소로 올립니다(push).
2. Vercel 에 로그인해 **Add New > Project** 에서 그 저장소를 가져옵니다(Import).
3. **Root Directory** 를 `web` 으로 지정합니다.
4. **Deploy** 를 누르고, 끝나면 나오는 배포 주소(`https://….vercel.app`)를 열어 확인합니다.

## VS Code 에서 작업하기

1. VS Code 에서 **이 저장소 폴더 하나**를 엽니다. (`파일 > 폴더 열기`) 오른쪽 아래에 뜨는 "권장 확장 설치"를 누릅니다.
2. `Ctrl+Shift+P` → `Tasks: Run Task` 에서 고릅니다.

| 작업 | 하는 일 |
|---|---|
| 웹 실행 (web · localhost:3000) | 웹 개발 서버를 띄움 |
| 검사: 웹 (lint · 타입 · 테스트) | 고친 뒤 깨진 곳이 없는지 확인 |

## 내 주제로 바꾸기

`web/src/lib/brand.ts`(이름·문구)와 `web/src/app/globals.css`(색)를 고칩니다.

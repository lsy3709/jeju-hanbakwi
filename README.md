# 제주 한 바퀴

> **이 브랜치는 2일차 수업이 끝난 상태입니다.** 오늘까지 만든 것: 웹(홈·탐색·상세 — 임시 데이터 `web/src/lib/sample-spots.json` 12건으로 동작), DB 테이블(`supabase/migrations`)과 임시 데이터 `supabase/seed_step2.sql`, 서버의 첫 API(`/health`·`/meta`·`/spots`·`/spots/{id}`) / 다음 날 만드는 것: 외부 데이터 가공·적재(`transform.py`, `tools/sync_spots.py`), 날씨와 지도, 웹과 서버 연결 — [API 명세](docs/api.md)에는 있어도 이 브랜치의 서버에는 아직 없는 주소(`/weather`, `/photos`, `/status`, 검색·필터 인자 등)가 있습니다 / 완성본은 main 브랜치.

취향에 맞는 제주 관광지를 찾아보는 여행 서비스.
화면이 **서버를 거쳐 DB** 를 쓰는 구조를 처음부터 끝까지 따라 만들어 보는 수업용 샘플입니다.

```
[web  Next.js] ─(3일차에 연결)→ [api  FastAPI] ───→ Supabase (PostgreSQL)
     └ 지금은 임시 데이터(sample-spots.json)로 동작
```

| 폴더 | 내용 |
|---|---|
| `web/` | 웹 화면 (Next.js, Tailwind) |
| `api/` | 서버 (FastAPI) · 테스트 |
| `supabase/` | DB 테이블 정의 (SQL) |
| `docs/` | 문서 (아래 "문서" 표) |
| `dev/` | (강사용) Docker 로 띄우는 로컬 DB |

## 문서

| 문서 | 내용 |
|---|---|
| [구조와 설계](docs/architecture.md) | 층 나누기, 쓰인 설계 패턴, 자료가 흐르는 길, 테스트 전략 |
| [API 명세](docs/api.md) | 서버 주소와 응답 모양 (웹·앱이 함께 쓰는 약속) |
| [화면·디자인 기준](docs/design.md) | 디자인 토큰, 화면 구성 |
| [배포 안내](docs/deploy.md) | Supabase + Vercel 무료 등급에 올리는 순서 |
| [운영과 수정](docs/operations.md) | 올린 뒤 살펴보기, 데이터 바꾸기, "이걸 바꾸려면 어디를", 사고 대응 |
| [일차별 브랜치](docs/steps.md) | `step-1` ~ `step-6` 쓰는 방법 |
| [체크리스트](docs/CHECKLIST.md) | 무엇을 확인했고 무엇이 남았는지 |
| [코드 분석 기록](docs/code-analysis-2026-11-20.md) | 고친 것, 보류·기각한 것과 이유 |
| [사진 출처](docs/photo-credits.md) | 샘플 사진의 저작자와 라이선스 |

## 일차별 브랜치

`main` 은 완성본이고, `step-1` ~ `step-6` 은 각 일차 수업이 끝났을 때의 상태입니다. 전날 다 못 끝냈으면 그날 브랜치에서 다시 시작할 수 있습니다. 쓰는 방법은 [docs/steps.md](docs/steps.md).

| 브랜치 | 그날까지 있는 것 |
|---|---|
| `step-1` | Next.js 첫 화면 한 장 |
| `step-2` | 홈·탐색·상세(임시 데이터), DB 테이블, 서버 첫 API |
| `step-3` | 외부 데이터 가공·적재, 날씨, 웹과 서버 연결 |
| `step-4` | 구글 로그인, 찜 |
| `step-5` | AI 일정, 일정 저장, 앱 홈·탐색·상세 |
| `step-6` | 앱 로그인·찜·AI 플래너 (= `main`) |

## 지키는 규칙

1. 화면(web)은 DB 를 직접 부르지 않고 **반드시 서버(api)를 거칩니다.** (지금은 임시 데이터를 쓰고, 3일차에 서버와 연결합니다)
2. **비밀 키는 `api/.env` 에만** 둡니다. `.env` 파일은 git 에 올라가지 않습니다.

## 처음 실행하기

준비물: Node.js 22 이상 · Python 3.12 이상 · Supabase 프로젝트
폴더는 `C:\work\jeju-hanbakwi` 처럼 **영문 경로**에 두세요.

### 1. DB 만들기

Supabase 대시보드 > SQL Editor 에 [`supabase/migrations/`](supabase/migrations) 의 SQL 파일을 **번호 순서대로**(001 → 002) 붙여 넣고 실행합니다. 이어서 [`supabase/seed_step2.sql`](supabase/seed_step2.sql) 을 실행하면 임시 관광지 12건이 들어갑니다.

### 2. 서버 (api)

```bash
cd api
python -m venv .venv
.venv\Scripts\activate            # macOS·Linux: source .venv/bin/activate
pip install -r requirements-dev.txt
copy .env.example .env            # 그다음 .env 를 열어 값을 채웁니다
uvicorn main:app --reload
```

`http://localhost:8000/docs` 에서 주소를 직접 눌러 볼 수 있습니다. 테스트는 `pytest`.

### 3. 웹 (web)

```bash
cd web
npm install
npm run dev
```

`http://localhost:3000`

## VS Code 에서 작업하기

1. VS Code 에서 **이 저장소 폴더 하나**를 엽니다. (`파일 > 폴더 열기`) 오른쪽 아래에 뜨는 "권장 확장 설치"를 누릅니다.
2. `Ctrl+Shift+P` → `Tasks: Run Task` 에서 고릅니다.

| 작업 | 하는 일 |
|---|---|
| 서버 + 웹 함께 실행 | 터미널 두 개에 서버(8000)와 웹(3000)을 띄움 |
| 검사: 서버 테스트 / 웹 | 고친 뒤 깨진 곳이 없는지 확인 |

3. 로컬에서 확인하는 주소: 웹 `http://localhost:3000` · 서버 `http://localhost:8000/docs`

## 내 주제로 바꾸기 — 두 가지만

| 바꾸는 것 | 고치는 파일 |
|---|---|
| ① 데이터 | `api/constants.py`(테마 목록) · `web/src/lib/sample-spots.json`(임시 관광지) · `supabase/seed_step2.sql` |
| ② 브랜드 | `web/src/lib/brand.ts` · `web/src/app/globals.css`(색) |

더 많은 "이걸 바꾸려면 어디를"은 [운영과 수정](docs/operations.md)에, 올리는 방법은 [배포 안내](docs/deploy.md)에 있습니다.

## 쓰는 외부 서비스 (모두 무료 등급)

Supabase · Vercel

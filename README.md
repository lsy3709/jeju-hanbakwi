# 제주 한 바퀴

날씨와 취향에 맞춰 제주 여행 일정을 짜 주는 AI 여행 플래너.
웹과 앱이 **같은 서버, 같은 DB** 를 쓰는 구조를 처음부터 끝까지 따라 만들어 보는 수업용 샘플입니다.

```
[web  Next.js] ─┐                     ┌─ Supabase (PostgreSQL · 구글 로그인)
                ├─→ [api  FastAPI] ───┼─ Gemini (AI 일정)
[app  Flutter] ─┘                     └─ Open-Meteo (날씨)

[api/tools/sync_spots.py]  한국관광공사 TourAPI → 우리 기준으로 고치기 → DB 에 넣기
```

| 폴더 | 내용 |
|---|---|
| `web/` | 웹 화면 (Next.js, Tailwind) |
| `app/` | 앱 화면 (Flutter — 안드로이드 · 웹) |
| `api/` | 서버 (FastAPI) · 데이터 가져오기 도구 · 테스트 |
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

1. 화면(web, app)은 DB·AI·외부 API 를 직접 부르지 않고 **반드시 서버(api)를 거칩니다.**
2. **로그인만 예외**입니다. 화면이 Supabase 로 구글 로그인을 하고, 받은 토큰을 서버에 보내 확인받습니다.
3. **비밀 키는 `api/.env` 에만** 둡니다. `.env` 파일은 git 에 올라가지 않습니다.
4. 외부 데이터는 미리 받아 **우리 기준으로 고쳐 DB 에** 둡니다.

## 처음 실행하기

준비물: Node.js 22 이상 · Python 3.12 이상 · Flutter 3.35 이상 · Supabase 프로젝트
폴더는 `C:\work\jeju-hanbakwi` 처럼 **영문 경로**에 두세요.

### 1. DB 만들기

Supabase 대시보드 > SQL Editor 에 [`supabase/migrations/`](supabase/migrations) 의 SQL 파일을 **번호 순서대로**(001 → 002) 붙여 넣고 실행합니다.

### 2. 서버 (api)

```bash
cd api
python -m venv .venv
.venv\Scripts\activate            # macOS·Linux: source .venv/bin/activate
pip install -r requirements-dev.txt
copy .env.example .env            # 그다음 .env 를 열어 값을 채웁니다
python -m tools.sync_spots --sample   # 샘플 관광지 68건 넣기 (사진 포함)
uvicorn main:app --reload
```

`http://localhost:8000/docs` 에서 주소를 직접 눌러 볼 수 있습니다. 테스트는 `pytest`.

### 3. 웹 (web)

```bash
cd web
npm install
copy .env.local.example .env.local
npm run dev
```

`http://localhost:3000`

### 4. 앱 (app)

```bash
cd app
flutter pub get
copy env.example.json env.json
flutter run --dart-define-from-file=env.json
```

- 코드는 VS Code 에서 작성하고, 에뮬레이터는 Android Studio 의 Device Manager 로 한 번만 만들어 둡니다.
- 에뮬레이터 켜기: VS Code 오른쪽 아래 기기 선택, 또는 `flutter emulators --launch <이름>`
- 에뮬레이터에서 내 PC 의 서버 주소는 `http://10.0.2.2:8000` 입니다. (`localhost` 가 아닙니다)
- 화면만 빨리 볼 때: `flutter run -d chrome --dart-define-from-file=env.json`

## VS Code 에서 작업하기

1. VS Code 에서 **이 저장소 폴더 하나**를 엽니다. (`파일 > 폴더 열기`) 오른쪽 아래에 뜨는 "권장 확장 설치"를 누릅니다.
2. `Ctrl+Shift+P` → `Tasks: Run Task` 에서 고릅니다.

| 작업 | 하는 일 |
|---|---|
| 서버 + 웹 함께 실행 | 터미널 두 개에 서버(8000)와 웹(3000)을 띄움 |
| 3. 앱 실행 - 크롬 / 에뮬레이터 | Flutter 앱 실행 (에뮬레이터는 먼저 켜 두기) |
| 검사: 서버 테스트 / 웹 / 앱 | 고친 뒤 깨진 곳이 없는지 확인 |
| 데이터: 샘플 관광지 넣기 | DB 에 샘플 68건 넣기 |

3. 로컬에서 확인하는 주소: 웹 `http://localhost:3000` · 서버 `http://localhost:8000/docs`
4. 앱은 `F5`(실행 및 디버그 > "앱 실행 (Flutter)")로도 실행할 수 있고, 저장하면 화면이 바로 바뀝니다.

### 에뮬레이터가 바로 꺼질 때

에뮬레이터 창이 떴다가 사라지면(로그에 `WHPX: Unexpected VP exit` 등), 저장된 상태를 쓰지 않고 새로 부팅합니다.

```bash
emulator -avd Pixel_4 -no-snapshot -gpu swiftshader_indirect
```

`emulator` 명령은 Android SDK 의 `emulator` 폴더에 있습니다. 그래도 안 되면 자기 안드로이드 폰을 USB 로 연결하거나 크롬으로 실행합니다.

## 실측 점검 — 서버와 DB 가 정말 연결됐는지

단위 테스트(`pytest`)는 가짜 DB 로 논리를 보고, 실측 점검은 **켜져 있는 서버를 실제로 불러** DB 와 외부 서비스까지 다녀온 결과를 봅니다.

```bash
cd api
python -m tools.check_live                           # 로그인 없이 볼 수 있는 것
python -m tools.check_live --token local-dev-token   # 로컬 Docker DB: 찜·일정 저장까지
python -m tools.check_live --api https://내서버.vercel.app --skip-ai   # 배포한 서버
```

진짜 Supabase 를 쓸 때는 웹에서 구글 로그인한 뒤의 액세스 토큰을 `--token` 에 넣습니다. 찜·일정 점검은 만든 것을 스스로 지웁니다.

## 데이터 가져오기

```bash
cd api
python -m tools.sync_spots --sample        # 샘플 (키 없이 가능)
python -m tools.sync_spots --dry-run       # TourAPI 에서 받아 결과만 보기 (TOUR_API_KEY 필요)
python -m tools.sync_spots --types 12,14   # 관광지·문화시설만 받아 DB 에 넣기
```

원본에 **테마 태그 · 실내/실외 · 지역 · 한 줄 소개**를 붙이는 규칙은 [`api/transform.py`](api/transform.py) 에 있습니다.

> 샘플 데이터(`api/data/sample_spots.json`)의 글은 수업용으로 직접 쓴 것이며 좌표와 주소는 대략값입니다. 실제 서비스에는 TourAPI 데이터를 쓰세요.
> 샘플 사진(`api/static/photos/`)은 위키미디어 공용의 공개 라이선스 사진이며, 사진별 저작자와 라이선스는 [docs/photo-credits.md](docs/photo-credits.md) 에 있습니다. 사진은 우리 서버가 `/photos/...` 주소로 직접 내줍니다.

### 예시 찜·일정 넣기

"내 여행" 화면이 비어 있으면 만들거나 시연하기 어렵습니다. 로그인한 내 계정에 찜 6개와 일정 2개를 넣어 줍니다.

```bash
cd api
python -m tools.seed_demo --token local-dev-token     # 로컬 Docker DB
python -m tools.seed_demo --token <액세스 토큰>        # 진짜 Supabase
python -m tools.seed_demo --token ... --clear         # 내 찜과 일정 모두 지우기
```

## 구글 로그인 켜기

화면별 자세한 순서는 [docs/deploy.md](docs/deploy.md) 4단계에 있습니다.

1. Google Cloud Console 의 "Google 인증 플랫폼"에서 동의 화면을 만들고 테스트 사용자에 내 계정을 넣은 뒤, OAuth 클라이언트(웹 애플리케이션)를 만들고 승인된 리디렉션 URI 에 `https://<프로젝트>.supabase.co/auth/v1/callback` 을 넣습니다.
2. Supabase > Authentication > Sign In / Providers > Google 을 켜고 클라이언트 ID 와 비밀을 넣습니다.
3. Supabase > Authentication > URL Configuration 의 Redirect URLs 에 추가합니다.
   - 웹: `http://localhost:3000/my`, `http://localhost:3000/planner` (배포 후에는 배포 주소의 두 화면도)
   - 앱: `com.goldmagnet.jejuhanbakwi://login-callback`
4. `web/.env.local` 과 `app/env.json` 에 Supabase URL 과 공개 키(anon)를 넣습니다.

## 내 주제로 바꾸기 — 세 가지만

| 바꾸는 것 | 고치는 파일 |
|---|---|
| ① 데이터 | `api/constants.py`(테마 목록) · `api/transform.py`(태그 규칙) · `sync_spots --types` |
| ② 브랜드 | `web/src/lib/brand.ts` · `web/src/app/globals.css`(색) · `app/lib/brand.dart` · `app/lib/theme.dart` |
| ③ AI 역할 | `api/services/plan_ai.py` 의 `SYSTEM_PROMPT` 와 도구 |

더 많은 "이걸 바꾸려면 어디를"은 [운영과 수정](docs/operations.md)에, 올리는 방법은 [배포 안내](docs/deploy.md)에 있습니다.

## 쓰는 외부 서비스 (모두 무료 등급)

한국관광공사 TourAPI(공공데이터포털) · Open-Meteo · OpenStreetMap · AWS Terrain Tiles(3D 지도의 높이 자료) · Google Gemini · Supabase · Vercel

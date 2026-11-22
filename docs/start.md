# 시작하는 방법 — 웹 · 앱 · 로컬

「제주 한 바퀴」를 켜는 방법을 세 가지 상황으로 나눠 적었습니다. 2026-11-23 에 PC 를 껐다 켠 상태에서 아래 순서 그대로 따라 해 확인했습니다.

| 하고 싶은 일 | 볼 곳 |
|---|---|
| 설치 없이 올려 둔 것을 바로 써 보기 | [A. 배포된 웹 · 앱](#a-배포된-웹--앱-바로-써-보기) |
| 내 PC 에서 전부 켜서 고쳐 보기 | [B. 로컬에서 전부 켜기](#b-로컬에서-전부-켜기) |
| 내 PC 화면을 진짜 Supabase(구글 로그인)에 붙이기 | [C. 로컬 화면 + 클라우드](#c-로컬-화면--클라우드-supabase) |
| 어제 하던 것을 다시 켜기 | [매일 다시 켜는 순서](#매일-다시-켜는-순서) |

처음 한 번 하는 설치(가상 환경 · `npm install` · `flutter pub get` · 설정 파일 복사)는 [README 의 "처음 실행하기"](../README.md#처음-실행하기)에 있습니다. 이 문서는 그 뒤 "켜는 법"을 다룹니다.

---

## 세 조각과 주소

```
[웹 3000] ─┐
           ├─→ [서버 8000] ─→ [DB 54321 또는 Supabase]
[앱]      ─┘
```

| 조각 | 로컬 주소 | 배포 주소 |
|---|---|---|
| 서버 (`api/`) | `http://localhost:8000` (눌러 보는 문서: `/docs`, 상태: `/status`) | `https://jeju-hanbakwi-api.vercel.app` |
| 웹 (`web/`) | `http://localhost:3000` | `https://jeju-hanbakwi-web.vercel.app` |
| 앱 (`app/`) | 에뮬레이터 안에서 서버는 `http://10.0.2.2:8000` | 설치 파일을 직접 만들어 설치 |
| DB | Docker `http://localhost:54321` | Supabase 프로젝트 |

켜는 순서는 언제나 **DB → 서버 → 웹 · 앱**입니다. 화면은 서버가 없으면 "불러오지 못했어요"만 보여 줍니다.

---

## A. 배포된 웹 · 앱 바로 써 보기

### 웹

브라우저에서 `https://jeju-hanbakwi-web.vercel.app` 을 엽니다. 설치할 것이 없습니다.

- 홈 · 탐색 · 상세 · AI 플래너는 로그인 없이 됩니다.
- 찜 · 일정 저장은 "내 여행"에서 **구글로 로그인**한 뒤에 됩니다. 구글 동의 화면이 "테스트 중"인 동안에는 테스트 사용자로 넣어 둔 계정만 로그인됩니다([배포 안내](deploy.md) 4-2).
- 관리자 화면(`/admin`)은 서버 환경변수 `ADMIN_EMAILS` 에 적힌 계정으로 로그인했을 때만 메뉴에 나타납니다.

### 앱 — 배포 서버에 붙여 설치하기

앱은 만들 때 서버 주소를 넣습니다. `env.json` 은 로컬용으로 두고, 배포 주소는 명령에 직접 적습니다.

```bash
cd app
flutter build apk --debug --dart-define=API_URL=https://jeju-hanbakwi-api.vercel.app --dart-define=SUPABASE_URL=https://<프로젝트>.supabase.co --dart-define=SUPABASE_ANON_KEY=<공개 키>
```

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

- `<공개 키>`는 Supabase > Project Settings > API Keys 의 **Publishable key**(`sb_publishable_…`)입니다. 화면에 넣어도 되는 값입니다. Secret key 는 절대 넣지 않습니다.
- 에뮬레이터나 USB 로 연결한 폰이 켜져 있어야 `adb install` 이 됩니다. `adb` 는 Android SDK 의 `platform-tools` 폴더에 있습니다.
- 앱에서 "구글로 로그인"을 누르면 브라우저가 열리고, 로그인이 끝나면 앱으로 돌아옵니다. 돌아오지 않으면 Supabase 의 Redirect URLs 에 `com.goldmagnet.jejuhanbakwi://login-callback` 이 있는지 봅니다.
- 로그인 버튼을 누른 채 몇 분 두면 `bad_oauth_state` 로 실패합니다. 누르면 바로 끝까지 진행합니다.

---

## B. 로컬에서 전부 켜기

Supabase 프로젝트 없이 내 PC 안에서만 돌립니다. 터미널을 네 개 씁니다(저장소 폴더에서 시작).

### 1. DB — Docker

Docker Desktop 을 먼저 켭니다.

```bash
docker compose -f dev/docker-compose.yml up -d
```

- 처음 켤 때 `supabase/migrations/` 의 SQL(001 → 003)이 자동으로 실행됩니다.
- `api/.env` 에는 이렇게 넣어 둡니다.

  ```
  SUPABASE_URL=http://localhost:54321
  SUPABASE_SERVICE_ROLE_KEY=local.dev.key
  ADMIN_EMAILS=local-tester@example.com
  ```

- 처음 한 번, 서버 가상 환경을 켠 터미널에서 샘플 68건을 넣습니다: `python -m tools.sync_spots --sample`
- 끄기: `docker compose -f dev/docker-compose.yml down` (데이터 유지). 끝에 `-v` 를 붙이면 데이터까지 지웁니다.

### 2. 서버

```bash
cd api
.venv\Scripts\activate
uvicorn main:app --reload
```

`http://localhost:8000/status` 가 `"database":"ok"` 와 `"spots":68` 을 보여 주면 DB 까지 연결된 것입니다.

### 3. 웹

`web/.env.local` 의 `NEXT_PUBLIC_API_URL` 이 `http://localhost:8000` 인지 확인하고 켭니다.

```bash
cd web
npm run dev
```

`http://localhost:3000`

### 4. 앱

에뮬레이터를 먼저 켭니다(VS Code 오른쪽 아래 기기 선택, 또는 아래 명령).

```bash
emulator -avd Pixel_4 -no-snapshot -gpu swiftshader_indirect
```

`app/env.json` 의 `API_URL` 이 `http://10.0.2.2:8000` 인지 확인하고 실행합니다.

```bash
cd app
flutter run --dart-define-from-file=env.json
```

- 에뮬레이터 없이 화면만 볼 때: `flutter run -d chrome --dart-define-from-file=env.json`. 이때는 `env.json` 의 `API_URL` 을 `http://localhost:8000` 으로 바꿔야 합니다(`10.0.2.2` 는 에뮬레이터 전용 주소).
- 실제 폰을 USB 로 연결했다면 `API_URL` 에 PC 의 내부 IP(`http://192.168.x.x:8000`)를 넣고, 서버를 `uvicorn main:app --host 0.0.0.0` 으로 켭니다. 폰과 PC 가 같은 와이파이여야 합니다. (이 방법은 실제 폰으로 확인해 보지 못했습니다.)

### 5. 다 켜졌는지 한 번에 확인

```bash
cd api
python -m tools.check_live --token local-dev-token
```

`결과: 35개 통과, 0개 실패` 가 나오면 서버 · DB · 찜 · 일정 · 관리자 주소까지 살아 있는 것입니다.

### 로컬에서 로그인이 필요한 화면 보기

로컬 Docker DB 에는 구글 로그인이 없습니다. 대신 `local-dev-token` 이라는 가짜 토큰을 "로그인한 사람"으로 받아 줍니다.

- 서버만 볼 때: `curl -H "Authorization: Bearer local-dev-token" http://localhost:8000/me`
- 도구로 볼 때: `--token local-dev-token` (`check_live`, `seed_demo`).
- 웹 · 앱 화면에서 진짜 로그인 흐름을 보려면 [C](#c-로컬-화면--클라우드-supabase)처럼 진짜 Supabase 에 붙입니다.

### VS Code 로 한 번에

`Ctrl+Shift+P` → `Tasks: Run Task` → **서버 + 웹 함께 실행**. 앱은 **3. 앱 실행 - 에뮬레이터** 또는 `F5`. (DB 는 1번 명령으로 먼저 켜 둡니다.)

---

## C. 로컬 화면 + 클라우드 Supabase

내 PC 에서 고친 화면으로 진짜 구글 로그인까지 해 볼 때입니다. Docker 는 필요 없습니다.

| 파일 | 넣는 값 |
|---|---|
| `api/.env` | `SUPABASE_URL=https://<프로젝트>.supabase.co`, `SUPABASE_SERVICE_ROLE_KEY=<Secret key>`, `ADMIN_EMAILS=<내 구글 계정>` |
| `web/.env.local` | `NEXT_PUBLIC_API_URL=http://localhost:8000`, `NEXT_PUBLIC_SUPABASE_URL=https://<프로젝트>.supabase.co`, `NEXT_PUBLIC_SUPABASE_ANON_KEY=<공개 키>` |
| `app/env.json` | `API_URL` 은 그대로, `SUPABASE_URL` 과 `SUPABASE_ANON_KEY` 에 같은 값 |

- Secret key 는 `api/.env` 에만 넣습니다. 채팅 · 캡처 · 화면 코드에 넣지 않습니다.
- Supabase > Authentication > URL Configuration 의 Redirect URLs 에 `http://localhost:3000/my` 와 `http://localhost:3000/planner` 가 있어야 로컬 웹으로 돌아옵니다.
- 값을 바꾼 뒤에는 서버와 웹을 껐다 켭니다. 앱은 다시 `flutter run` 합니다.
- 로컬 DB 와 클라우드를 오가며 쓸 때는 `api/.env`(로컬용)와 `api/.env.cloud`(클라우드용)를 따로 두고, 도구를 돌릴 때만 `set -a && . ./.env.cloud && set +a` 로 바꿔 쓰는 방법이 헷갈리지 않습니다.

그다음은 B 의 2 ~ 4번과 같습니다.

---

## 매일 다시 켜는 순서

| 순서 | 명령 | 확인 |
|---|---|---|
| 1 | Docker Desktop 켜기 → `docker compose -f dev/docker-compose.yml up -d` | `docker compose -f dev/docker-compose.yml ps` 에 세 개가 Up |
| 2 | `cd api` → `.venv\Scripts\activate` → `uvicorn main:app --reload` | `http://localhost:8000/status` |
| 3 | `cd web` → `npm run dev` | `http://localhost:3000` |
| 4 | 에뮬레이터 켜기 → `cd app` → `flutter run --dart-define-from-file=env.json` | 홈에 날씨와 추천 카드 |

C 방식으로 쓰는 날은 1번을 건너뜁니다. 끌 때는 각 터미널에서 `Ctrl+C`, DB 는 `docker compose -f dev/docker-compose.yml down`.

## 켜지지 않을 때

| 증상 | 볼 곳 |
|---|---|
| 웹 · 앱이 "불러오지 못했어요" | 서버가 켜져 있는지(`/status`). 앱이면 `API_URL` 이 `10.0.2.2` 인지 |
| `/status` 의 `database` 가 `ok` 가 아님 | Docker 세 개가 Up 인지, `api/.env` 의 `SUPABASE_URL` |
| `spots` 가 0 | `python -m tools.sync_spots --sample` 을 아직 안 함 |
| 코드를 고쳤는데 서버 · 웹이 그대로 | 드물게 저장을 못 알아챕니다. `Ctrl+C` 로 끄고 다시 켭니다 |
| 포트가 이미 쓰이고 있다는 오류 | 전에 켠 터미널이 남아 있습니다. 그 터미널을 닫거나 `netstat -ano \| findstr :8000` 으로 찾아 끕니다 |
| 에뮬레이터 창이 떴다가 사라짐 | `-no-snapshot -gpu swiftshader_indirect` 를 붙여 켭니다 |
| 에뮬레이터에 "Chrome isn't responding" | Wait 를 누르거나 `adb shell am force-stop com.android.chrome` |
| 웹에서 로그인 버튼 대신 "로그인 설정이 아직 없어요" | `web/.env.local` 의 Supabase 두 값이 비어 있음(B 방식에서는 정상) |
| 앱 로그인 뒤 앱으로 돌아오지 않음 | Supabase Redirect URLs 의 앱 주소 |
| 폴더가 한글 경로 | Node · Next 가 멈춥니다. `C:\work\jeju-hanbakwi` 처럼 영문 경로로 옮깁니다 |

더 많은 경우는 [배포 안내의 "자주 막히는 곳"](deploy.md#자주-막히는-곳)과 [운영과 수정](operations.md)에 있습니다.

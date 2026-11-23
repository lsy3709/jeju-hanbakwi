# 배포 안내 — Supabase + Vercel (무료 등급)

로컬에서 다 확인한 뒤에 올립니다. 순서는 **DB → 서버 → 웹 → 앱** 입니다.
앞 단계의 주소가 뒤 단계의 설정 값이 되기 때문입니다.

> 1 ~ 4단계(DB · 서버 · 웹 · 구글 로그인)와 6단계의 실측 점검은 2026-11-22 에 실제로 올려 확인한 절차입니다. 구글 로그인은 웹에서만 확인했고, 5단계(앱)는 아직 실제로 해 보지 않았습니다. 대시보드 화면의 이름은 자주 바뀌니, 다르면 비슷한 이름을 찾으세요. 무료 등급의 한도(프로젝트 수, 사용량, 응답 시간 제한)도 자주 바뀌므로 각 서비스의 요금 안내에서 확인하세요.

## 준비물

| 계정 | 쓰는 곳 |
|---|---|
| GitHub | 코드 저장소 (이 저장소를 Fork 한 내 저장소) |
| Supabase | DB, 구글 로그인 |
| Vercel | 서버·웹·앱 배포 (GitHub 계정으로 가입) |
| Google AI Studio | AI 키 (없어도 됨 — 규칙 방식으로 동작) |
| Google Cloud | 구글 로그인용 OAuth 클라이언트 |

## 1. DB — Supabase

1. **New project** 를 누르고 이름과 DB 비밀번호를 정합니다. 비밀번호는 **Generate a password** 로 만들고 내 비밀번호 관리 도구에 적어 둡니다. 이 수업의 코드에는 쓰지 않습니다.
2. **지역은 Northeast Asia (Seoul)** 을 고릅니다. 지역 칸이 보이지 않으면 "Need a specific region?" 을 눌러 목록을 엽니다. 목록이 길어 아래로 내려야 서울이 보입니다.
3. 아래쪽 Data access 의 선택 칸은 처음 값 그대로 둡니다(Data API 켬, 테이블 자동 공개 켬, 자동 RLS 끔). RLS 는 우리 SQL 이 직접 켭니다.
4. 프로젝트가 준비되면(1 ~ 2분) **SQL Editor** 에서 [`supabase/migrations/`](../supabase/migrations) 의 파일을 **번호 순서대로** 붙여 넣고 **Run** 을 누릅니다 (001 → 002 → 003). 결과 칸에 "Success. No rows returned" 가 나오면 된 것입니다. 편집기가 "자동 저장하지 않는다"는 안내 창을 띄우면 닫고 계속합니다.
5. **Project Settings → API Keys** 에서 키를, **Project Settings → Data API**(또는 화면 위 **Connect**)에서 주소를 확인합니다.

| 값 | 화면에 보이는 이름 | 생김새 | 어디에 쓰나 | 공개해도 되나 |
|---|---|---|---|---|
| 프로젝트 주소 | Project URL | `https://<프로젝트 ID>.supabase.co` | 서버·웹·앱 | 됨 |
| 공개 키 | Publishable key | `sb_publishable_…` | 웹·앱 — 로그인에만 | 됨 |
| 비밀 키 | Secret key | `sb_secret_…` | **서버에만** | **안 됨** |

예전 이름인 `anon` · `service_role` 키(`eyJ…` 로 시작)는 "Legacy API keys" 쪽에 따로 있습니다. 새 프로젝트는 위 표의 새 키를 씁니다. 이 저장소의 환경변수 이름(`SUPABASE_SERVICE_ROLE_KEY`, `…_ANON_KEY`)은 예전 이름 그대로지만, 값에는 새 키를 넣으면 됩니다(서버는 새 비밀 키로 동작하는 것을 확인했습니다).

6. 내 PC 의 `api/.env` 에 Project URL 과 비밀 키를 넣고 데이터를 넣습니다.

```bash
python -m tools.sync_spots --sample
```

"DB 에 68건을 넣었습니다" 가 나오고, Supabase 의 Table Editor 에서 `spots` 에 68줄이 보이면 됩니다. "Invalid API key" 가 나오면 키 칸에 주소나 공개 키를 넣은 것입니다. 비밀 키는 `sb_secret_` 로 시작합니다.

## 2. 서버 — Vercel 프로젝트 ①

1. Vercel 에서 **Add New → Project** → 내 저장소 옆의 **Import** 를 누릅니다.
2. Vercel 이 저장소 안의 폴더를 알아보고 `api` 와 `web` 을 따로 보여 줍니다. **`api` 줄의 "Import single project"** 를 누릅니다. 이렇게 하면 Root Directory 가 `api` 로, Framework Preset 이 FastAPI 로 잡힙니다. (폴더 목록이 나오지 않으면 Root Directory 의 **Edit** 을 눌러 `api` 를 직접 고릅니다. 가장 자주 빠뜨리는 곳입니다. 폴더 둘을 한 프로젝트로 묶는 "Services" 제안은 쓰지 않습니다.)
3. Project Name 을 정합니다(예: `jeju-hanbakwi-api`). 이 이름이 주소가 됩니다.
4. **Environment Variables** 를 펼쳐 넣습니다. 지금 넣지 않고 배포한 뒤 Settings → Environment Variables 에서 넣어도 됩니다.

| 이름 | 값 | 종류 |
|---|---|---|
| `SUPABASE_URL` | Supabase Project URL | Config |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 비밀 키 (`sb_secret_…`) | **Secret** |
| `GEMINI_API_KEY` | AI 키 (없으면 만들지 않음) | **Secret** |
| `ALLOWED_ORIGINS` | 웹 주소. 3단계 뒤에 넣음 | Config |
| `PUBLIC_API_URL` | 이 서버의 주소. 첫 배포 뒤에 넣음 | Config |
| `ADMIN_EMAILS` | 관리자로 쓸 구글 계정 이메일(여럿이면 쉼표로). 넣지 않으면 관리자 화면을 아무도 못 씀 | Config |

변수를 더하는 창에서 종류(Secret · Config)를 고릅니다. Secret 은 저장한 뒤 다시 볼 수 없으므로 비밀 키에 씁니다. 적용 환경은 처음 값인 Production 그대로 둡니다.

5. **Deploy** 를 누릅니다. 끝나면 주소가 둘 나옵니다.

| 주소 | 쓰임 |
|---|---|
| `https://<프로젝트 이름>.vercel.app` | **이 주소를 씁니다.** 누구나 열 수 있습니다 |
| `https://<프로젝트 이름>-<글자들>-<팀 이름>.vercel.app` | 그 배포 하나만 가리키는 주소. Vercel 로그인을 요구하므로 화면 설정 값으로 쓰지 않습니다 |

6. 브라우저에서 확인합니다.

| 주소 | 기대하는 결과 |
|---|---|
| `/health` | `{"status":"ok"}` |
| `/status` | `database: "ok"`, `spots: 68`, `photos: 55` |
| `/docs` | 주소 목록 화면 |
| `/spots/1` | `image_url` 이 `https://` 로 시작 |

`/health` 는 되는데 `/status` 가 500 이면 서버가 DB 값을 받지 못한 것입니다. 변수 이름, 변수를 넣은 프로젝트(서버인지 웹인지), 넣은 뒤 다시 배포했는지를 차례로 봅니다.

`image_url` 이 `http://` 로 나오면 환경변수 `PUBLIC_API_URL` 에 서버 주소를 넣고 다시 배포합니다.

서버가 도는 지역은 [`api/vercel.json`](../api/vercel.json) 에서 서울(`icn1`)로 정해 두었습니다. DB 와 서버가 같은 지역에 있어야 빠릅니다. Supabase 를 다른 지역에 만들었다면 이 값을 그 지역에 맞춥니다.

## 3. 웹 — Vercel 프로젝트 ②

1. 다시 **Add New → Project** → 같은 저장소 → 이번에는 **`web` 줄의 "Import single project"** 를 누릅니다(Root Directory `web`, Framework Preset Next.js).
2. Environment Variables:

| 이름 | 값 | 종류 |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | 2단계의 서버 주소(짧은 쪽) | Config |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase Project URL | Config |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase 공개 키 (`sb_publishable_…`) | Config |

`NEXT_PUBLIC_` 으로 시작하는 값은 브라우저에 그대로 보입니다. **비밀 키를 넣지 마세요.** 웹 프로젝트에는 위 세 개만 있으면 됩니다.

3. **Deploy** 를 누릅니다. 프로젝트를 만든 뒤 Supabase 같은 연동을 권하는 칸이 먼저 나오면, 연동은 하지 않고 그 아래의 **Deploy** 를 누릅니다. 끝나면 주소(`https://<프로젝트 이름>.vercel.app`)를 적어 둡니다.
4. 서버 프로젝트(①)의 `ALLOWED_ORIGINS` 에 이 주소를 넣고, 서버를 **다시 배포**합니다. 주소 끝에 `/` 를 붙이지 않습니다. 로컬에서도 계속 쓰려면 쉼표로 이어 `https://<웹 주소>,http://localhost:3000` 처럼 적습니다.

### 환경변수를 바꾼 뒤 — Redeploy

환경변수는 저장만으로는 반영되지 않습니다. **Deployments** 에서 맨 위 배포의 `⋯` → **Redeploy** → 확인 창의 **Redeploy** 를 눌러야 새 값으로 다시 만들어집니다. `NEXT_PUBLIC_` 값은 빌드할 때 화면 코드에 들어가므로 웹도 마찬가지입니다.

변수를 넣기 전에 **화면 위쪽의 프로젝트 이름**을 꼭 봅니다. 서버와 웹 프로젝트의 화면이 똑같이 생겨서, 비밀 키를 웹 프로젝트에 넣는 실수가 잦습니다. 잘못 넣었으면 그 줄의 `⋯` → **Delete** 로 지우고 서버 프로젝트에 다시 넣습니다.

## 4. 구글 로그인

세 곳을 차례로 설정합니다. 화면 이름은 2026-11-22 기준입니다.

### 4-1. Supabase — 돌아올 주소

Authentication → URL Configuration 에서:

| 항목 | 값 |
|---|---|
| Site URL | 웹 주소 (처음 값은 `http://localhost:3000`). 바꾸고 **Save changes** |
| Redirect URLs | **Add URL** 을 눌러 한 줄에 하나씩 넣고 **Save URLs**: `http://localhost:3000/my`, `http://localhost:3000/planner`, `<웹 주소>/my`, `<웹 주소>/planner`, `com.goldmagnet.jejuhanbakwi://login-callback` |

Redirect URLs 에 없는 주소로는 돌아오지 못합니다. 로그인 뒤 엉뚱한 화면이 열리면 여기를 먼저 봅니다.

### 4-2. Google Cloud Console — 동의 화면과 OAuth 클라이언트

1. https://console.cloud.google.com 에서 새 프로젝트를 만듭니다. 결제 계정이 있는 구글 계정은 "결제 계정"을 골라야 만들어집니다(구글 로그인만 쓰면 요금은 없습니다). 위쪽 프로젝트 이름이 방금 만든 것인지 확인합니다.
2. 메뉴에서 **Google 인증 플랫폼** → **시작하기** 를 누르고 네 단계를 채웁니다.

| 단계 | 넣는 것 |
|---|---|
| 앱 정보 | 앱 이름(로그인 화면에 보임), 사용자 지원 이메일(내 계정 선택) |
| 대상 | **외부** |
| 연락처 정보 | 내 이메일 |
| 완료 | "Google API 서비스: 사용자 데이터 정책" 동의에 체크 → **계속** → **만들기** |

3. **대상** 메뉴 → 테스트 사용자의 **Add users** 로 로그인해 볼 구글 계정을 넣고 저장합니다. 게시 상태가 "테스트 중"인 동안에는 **여기에 넣은 계정만** 로그인할 수 있습니다(100명까지).
4. **클라이언트** 메뉴 → 클라이언트 만들기:

| 칸 | 값 |
|---|---|
| 애플리케이션 유형 | 웹 애플리케이션 |
| 이름 | 알아볼 이름(로그인 화면에는 안 보임) |
| 승인된 JavaScript 원본 | 비워 둠 |
| 승인된 리디렉션 URI | `https://<프로젝트>.supabase.co/auth/v1/callback` — Supabase Project URL 뒤에 `/auth/v1/callback` |

5. **만들기** 를 누르면 클라이언트 ID 와 클라이언트 보안 비밀번호가 창에 나옵니다. **보안 비밀번호는 이 창을 닫으면 다시 보기 어렵습니다.** 창을 닫기 전에 다음 단계에 붙여 넣습니다. 캡처 · 채팅 · 코드에 넣지 않습니다.

### 4-3. Supabase — Google 공급자 켜기

Authentication → Sign In / Providers → **Google** 을 눌러 창을 열고:

| 칸 | 값 |
|---|---|
| Enable Sign in with Google | 켬 |
| Client IDs | 4-2 의 클라이언트 ID |
| Client Secret (for OAuth) | 4-2 의 클라이언트 보안 비밀번호 |

**Save** 를 누릅니다. 웹의 "구글로 로그인"을 눌러 구글의 계정 선택 화면이 나오면 연결된 것입니다.

## 5. 앱 (Flutter)

### 웹 빌드를 올리기 — Vercel 프로젝트 ③

Vercel 에는 Flutter 가 없어서, 내 PC 에서 빌드한 결과 폴더를 올립니다.

```bash
flutter build web --dart-define=API_URL=https://<서버 주소> --dart-define=SUPABASE_URL=https://<프로젝트>.supabase.co --dart-define=SUPABASE_ANON_KEY=<공개 키>
```

```bash
npx vercel deploy build/web --prod
```

처음 실행하면 로그인과 프로젝트 이름을 묻습니다. 끝나면 나오는 주소를 서버의 `ALLOWED_ORIGINS` 와 Supabase 의 Redirect URLs 에 더합니다.

### 안드로이드 설치 파일

```bash
flutter build apk --dart-define-from-file=env.json
```

`env.json` 의 `API_URL` 을 배포한 서버 주소로 바꾼 뒤 빌드합니다. 결과는 `build/app/outputs/flutter-apk/app-release.apk` 입니다.

## 6. 올린 뒤 확인

내 PC 에서 배포한 서버를 실측 점검합니다.

```bash
python -m tools.check_live --api https://<서버 주소>
```

끝에 "18개 통과, 0개 실패"가 나오면 됩니다(로그인 토큰 없이 돌렸을 때의 개수).

웹에서 로그인한 뒤의 흐름까지 보려면, 브라우저 개발자 도구의 Application → Local Storage 에서 `sb-...-auth-token` 의 `access_token` 을 복사해 `--token` 에 넣습니다.

| 확인할 것 | 방법 |
|---|---|
| 웹 홈에 날씨와 사진이 나온다 | 웹 주소 열기 |
| 탐색의 검색·필터·지도 | 웹에서 눌러 보기 |
| 구글 로그인 → 찜 → 내 여행 | 웹에서 |
| AI 일정이 응답 시간 제한 안에 온다 | 2~3일 일정을 요청해 보기. 실측 점검이 25초를 넘으면 경고함 |
| 일정 날짜가 오늘(한국 날짜)부터다 | 오전 9시 전에 시작 날짜 없이 짜 보기 |

## 자주 막히는 곳

| 증상 | 원인 | 해결 |
|---|---|---|
| Vercel 빌드가 "No framework detected" 또는 엉뚱한 것을 빌드 | Root Directory 를 안 정함 | 프로젝트 Settings → General → Root Directory |
| 서버 주소를 열면 Vercel 로그인 화면이 나옴 | 배포 하나만 가리키는 긴 주소를 씀 | `https://<프로젝트 이름>.vercel.app` 을 씀 |
| 키를 넣었는데 `/status` 의 `ai` 가 계속 `rule` | 변수 이름이 틀림(예: 맨 앞 글자가 빠진 `EMINI_API_KEY`), 또는 넣고 다시 배포하지 않음 | Vercel 편집 창에서는 Key(이름)를 고칠 수 없습니다. **Add Environment Variable** 로 바른 이름을 새로 만들고 틀린 줄은 `⋯` → Remove, 그다음 Redeploy |
| 웹에서 "서버에 연결할 수 없어요" | `NEXT_PUBLIC_API_URL` 이 비었거나, 서버의 `ALLOWED_ORIGINS` 에 웹 주소가 없음 | 값을 넣고 **다시 배포** |
| `/health` 는 되는데 `/status` · `/spots` 가 500 | 서버 프로젝트에 `SUPABASE_URL` · `SUPABASE_SERVICE_ROLE_KEY` 가 없음(웹 프로젝트에 넣었거나, 넣고 다시 배포하지 않음) | 서버 프로젝트에 넣고 Redeploy. Vercel 의 Logs 에 "SUPABASE_URL 과 SUPABASE_SERVICE_ROLE_KEY 를 넣어 주세요" 가 보임 |
| `sync_spots` 가 "Invalid API key" | 비밀 키 칸에 주소나 공개 키를 넣음 | `sb_secret_` 로 시작하는 값으로 |
| `/status` 의 `database` 가 `error` | Supabase 주소·비밀 키가 틀렸거나 SQL 을 실행하지 않음 | 1단계 다시 |
| `/status` 의 `spots` 가 0 | 데이터를 넣지 않음 | `python -m tools.sync_spots --sample` |
| 로그인 뒤 처음 화면으로 돌아감 | Redirect URLs 에 그 주소가 없음 | 4-1 의 표 |
| 로그인 뒤 홈으로 돌아가고 주소에 `error_code=bad_oauth_state` ("OAuth state has expired") | 구글의 계정 선택 화면을 몇 분 동안 띄워 둠 | 설정은 맞음. "구글로 로그인"을 다시 누르고 바로 계정을 고름 |
| 구글이 "액세스 차단됨"으로 막음 | 게시 상태가 "테스트 중"인데 그 계정이 테스트 사용자에 없음 | 4-2 의 3번 — **대상** → 테스트 사용자에 계정 추가 |
| "구글로 로그인"을 눌러도 구글 화면이 안 뜨고 오류 글이 나옴 | Supabase 의 Google 공급자가 꺼져 있거나 값을 저장하지 않음 | 4-3 — 켜고 **Save** |
| AI 일정이 "간단 추천"으로만 나옴 | AI 키가 없거나 한도 초과, 또는 모델 이름이 바뀜 | `/status` 의 `ai`, Vercel 의 서버 로그, `GEMINI_MODEL` |
| 관리자 메뉴가 안 보임, `/admin/users` 가 403 | 서버의 `ADMIN_EMAILS` 에 내 이메일이 없거나, 넣고 다시 배포하지 않음 | 값을 넣고 Redeploy. `/me` 의 `is_admin` 이 `true` 인지 확인 |
| 설정 · 관리자 화면의 AI 사용량이 "읽지 못했습니다(503)" | `004_ai_usage.sql` 을 실행하지 않음 | SQL 을 실행. 실행 전에도 일정 짜기는 그대로 됩니다(사용량만 적히지 않음) |
| 코드를 올린 뒤 `/spots` 가 500 | 새 SQL(`003_admin.sql`)을 실행하지 않음 | SQL 을 실행. Vercel Logs 에 `column spots.hidden does not exist` 가 보임 |
| 며칠 뒤 DB 가 응답하지 않음 | 무료 Supabase 프로젝트는 오래 쓰지 않으면 일시 정지됨 | Supabase 대시보드에서 다시 켜기 |
| 사진이 안 나옴 | 사진 주소가 `http://` 로 나옴 | `PUBLIC_API_URL` 설정 |

## 이미 올린 서비스에 SQL 을 더할 때 — 순서가 중요합니다

서버 코드가 새 칸이나 새 표를 쓰게 바뀌었으면(예: `003_admin.sql` 의 `hidden`, `profiles`), **SQL 을 먼저 실행하고 그다음에 코드를 올립니다.** 거꾸로 하면 새 서버가 없는 칸을 찾다가 목록 주소부터 500 을 냅니다.

| 순서 | 할 일 |
|---|---|
| 1 | Supabase SQL Editor 에서 새 SQL 파일 실행 (여러 번 실행해도 안전하게 써 두었습니다) |
| 2 | 새 환경변수가 있으면 Vercel 에 넣기 (예: `ADMIN_EMAILS`) |
| 3 | 코드 푸시 → 자동 배포 |
| 4 | `/status`, `python -m tools.check_live --api <서버 주소>` 로 확인 |

SQL 은 "더하기"만 하도록 씁니다(새 칸은 기본값을 주고, 있던 칸은 지우거나 이름을 바꾸지 않음). 그래야 SQL 을 먼저 실행해도 옛 서버가 그대로 돕니다.

## 다시 배포하기

`main` 브랜치에 푸시하면 Vercel 이 서버와 웹을 자동으로 다시 배포합니다.
환경변수만 바꿨을 때는 Vercel 의 Deployments 에서 **Redeploy** 를 눌러야 반영됩니다.
앱의 웹 빌드는 5단계의 두 명령을 다시 실행합니다.

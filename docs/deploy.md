# 배포 안내 — Supabase + Vercel (무료 등급)

로컬에서 다 확인한 뒤에 올립니다. 순서는 **DB → 서버 → 웹 → 앱** 입니다.
앞 단계의 주소가 뒤 단계의 설정 값이 되기 때문입니다.

> 이 문서의 절차는 아직 실제 배포로 끝까지 확인하지 않았습니다. 대시보드 화면의 이름은 바뀔 수 있으니, 다르면 비슷한 이름을 찾으세요. 무료 등급의 한도(프로젝트 수, 사용량, 응답 시간 제한)도 자주 바뀌므로 각 서비스의 요금 안내에서 확인하세요.

## 준비물

| 계정 | 쓰는 곳 |
|---|---|
| GitHub | 코드 저장소 (이 저장소를 Fork 한 내 저장소) |
| Supabase | DB, 구글 로그인 |
| Vercel | 서버·웹·앱 배포 (GitHub 계정으로 가입) |
| Google AI Studio | AI 키 (없어도 됨 — 규칙 방식으로 동작) |
| Google Cloud | 구글 로그인용 OAuth 클라이언트 |

## 1. DB — Supabase

1. 새 프로젝트를 만듭니다. **지역은 Northeast Asia (Seoul)** 을 고릅니다.
2. SQL Editor 에서 [`supabase/migrations/`](../supabase/migrations) 의 파일을 **번호 순서대로** 붙여 넣고 실행합니다 (001 → 002).
3. Project Settings 의 API 화면에서 세 값을 적어 둡니다.

| 값 | 어디에 쓰나 | 공개해도 되나 |
|---|---|---|
| Project URL | 서버·웹·앱 | 됨 |
| 공개 키 (anon 또는 publishable) | 웹·앱 — 로그인에만 | 됨 |
| 비밀 키 (service_role 또는 secret) | **서버에만** | **안 됨** |

4. 내 PC 의 `api/.env` 를 이 프로젝트 값으로 바꾸고 데이터를 넣습니다.

```bash
python -m tools.sync_spots --sample
```

Supabase 의 Table Editor 에서 `spots` 에 68줄이 들어갔는지 봅니다.

## 2. 서버 — Vercel 프로젝트 ①

1. Vercel 에서 **Add New → Project** → 내 저장소를 고릅니다.
2. **Root Directory 를 `api`** 로 지정합니다. (가장 자주 빠뜨리는 곳)
3. Environment Variables 에 넣습니다.

| 이름 | 값 |
|---|---|
| `SUPABASE_URL` | Supabase Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 비밀 키 |
| `GEMINI_API_KEY` | AI 키 (없으면 비워 둠) |
| `ALLOWED_ORIGINS` | 일단 비워 두고, 3·4단계 뒤에 웹·앱 주소를 넣음 |

4. Deploy 를 누르고, 끝나면 주소(예: `https://jeju-api-xxxx.vercel.app`)를 적어 둡니다.
5. 브라우저에서 확인합니다.

| 주소 | 기대하는 결과 |
|---|---|
| `/health` | `{"status":"ok"}` |
| `/status` | `database: "ok"`, `spots: 68`, `photos: 55` |
| `/docs` | 주소 목록 화면 |
| `/spots/1` | `image_url` 이 `https://` 로 시작 |

`image_url` 이 `http://` 로 나오면 환경변수 `PUBLIC_API_URL` 에 서버 주소를 넣고 다시 배포합니다.

서버가 도는 지역은 [`api/vercel.json`](../api/vercel.json) 에서 서울(`icn1`)로 정해 두었습니다. DB 와 서버가 같은 지역에 있어야 빠릅니다. Supabase 를 다른 지역에 만들었다면 이 값을 그 지역에 맞춥니다.

## 3. 웹 — Vercel 프로젝트 ②

1. 다시 **Add New → Project** → 같은 저장소 → **Root Directory 를 `web`** 으로.
2. Environment Variables:

| 이름 | 값 |
|---|---|
| `NEXT_PUBLIC_API_URL` | 2단계의 서버 주소 |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase Project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase 공개 키 |

`NEXT_PUBLIC_` 으로 시작하는 값은 브라우저에 그대로 보입니다. **비밀 키를 넣지 마세요.**

3. Deploy 후 주소(예: `https://jeju-web-xxxx.vercel.app`)를 적어 둡니다.
4. 서버 프로젝트(①)의 `ALLOWED_ORIGINS` 에 이 주소를 넣고, 서버를 **다시 배포**합니다. (환경변수는 다시 배포해야 반영됩니다)

## 4. 구글 로그인

1. Google Cloud Console 에서 OAuth 클라이언트(웹 애플리케이션)를 만들고, 승인된 리디렉션 URI 에 `https://<프로젝트>.supabase.co/auth/v1/callback` 을 넣습니다.
2. Supabase 의 Authentication → Providers → Google 에 클라이언트 ID 와 비밀을 넣습니다.
3. Supabase 의 Authentication → URL Configuration 에서:

| 항목 | 값 |
|---|---|
| Site URL | 웹 주소 |
| Redirect URLs | `http://localhost:3000/my`, `http://localhost:3000/planner`, `<웹 주소>/my`, `<웹 주소>/planner`, `com.goldmagnet.jejuhanbakwi://login-callback` |

Redirect URLs 에 없는 주소로는 돌아오지 못합니다. 로그인 뒤 엉뚱한 화면이 열리면 여기를 먼저 봅니다.

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
| 웹에서 "서버에 연결할 수 없어요" | `NEXT_PUBLIC_API_URL` 이 비었거나, 서버의 `ALLOWED_ORIGINS` 에 웹 주소가 없음 | 값을 넣고 **다시 배포** |
| `/status` 의 `database` 가 `error` | Supabase 주소·비밀 키가 틀렸거나 SQL 을 실행하지 않음 | 1단계 다시 |
| `/status` 의 `spots` 가 0 | 데이터를 넣지 않음 | `python -m tools.sync_spots --sample` |
| 로그인 뒤 처음 화면으로 돌아감 | Redirect URLs 에 그 주소가 없음 | 4단계 표 |
| AI 일정이 "간단 추천"으로만 나옴 | AI 키가 없거나 한도 초과, 또는 모델 이름이 바뀜 | `/status` 의 `ai`, Vercel 의 서버 로그, `GEMINI_MODEL` |
| 며칠 뒤 DB 가 응답하지 않음 | 무료 Supabase 프로젝트는 오래 쓰지 않으면 일시 정지됨 | Supabase 대시보드에서 다시 켜기 |
| 사진이 안 나옴 | 사진 주소가 `http://` 로 나옴 | `PUBLIC_API_URL` 설정 |

## 다시 배포하기

`main` 브랜치에 푸시하면 Vercel 이 서버와 웹을 자동으로 다시 배포합니다.
환경변수만 바꿨을 때는 Vercel 의 Deployments 에서 **Redeploy** 를 눌러야 반영됩니다.
앱의 웹 빌드는 5단계의 두 명령을 다시 실행합니다.

# 운영과 수정 — 올린 뒤에 하는 일

서비스는 올린 날부터가 시작입니다. 이 문서는 **살펴보기 · 데이터 바꾸기 · 고치기 · 사고 대응**을 다룹니다.

## 살펴보기

| 무엇을 | 어디서 |
|---|---|
| 서버가 살아 있고 무엇이 연결됐는지 | `https://<서버 주소>/status` |
| 주소별로 실제 응답이 맞는지 | `python -m tools.check_live --api https://<서버 주소>` |
| 서버 오류와 경고 (AI 실패 사유 등) | Vercel → 서버 프로젝트 → Logs |
| DB 내용 | Supabase → Table Editor |
| 로그인한 사용자 | Supabase → Authentication → Users |
| 사용량 (무료 한도) | 각 서비스 대시보드의 Usage |

`/status` 읽는 법:

| 값 | 뜻 | 조치 |
|---|---|---|
| `database: "error"` | DB 에 닿지 못함 | Supabase 가 일시 정지됐는지, 서버의 주소·비밀 키가 맞는지 |
| `spots: 0` | 테이블은 있는데 데이터가 없음 | 데이터 넣기 |
| `ai: "rule"` | AI 키가 없어 규칙으로만 일정을 짬 | 의도한 것이 아니면 `GEMINI_API_KEY` 확인 |
| `login: "off"` | Supabase 설정이 비어 있음 | 서버 환경변수 확인 |
| `photos: 0` | 사진 파일이 함께 올라가지 않음 | `api/static/photos/` 가 저장소에 있는지 |

## 데이터 바꾸기

데이터는 내 PC 에서 도구를 실행해 넣습니다. `api/.env` 가 가리키는 DB 에 들어갑니다.
**운영 DB 에 넣기 전에 `--dry-run` 으로 결과를 먼저 봅니다.**

| 하고 싶은 일 | 방법 |
|---|---|
| 샘플 68건으로 되돌리기 | `python -m tools.sync_spots --sample` |
| TourAPI 최신 데이터 받기 | `python -m tools.sync_spots --dry-run` 으로 확인 후 `--dry-run` 을 빼고 실행 |
| 받을 종류 바꾸기 | `--types 12,14` (12 관광지 · 14 문화시설 · 15 축제 · 28 레포츠 · 38 쇼핑 · 39 음식점) |
| 한 곳의 분류가 틀림 | `api/transform.py` 의 `CORRECTIONS` 표에 한 줄 더하고 다시 넣기 |
| 테마 태그 규칙 바꾸기 | `api/transform.py` 의 `THEME_KEYWORDS` + `api/constants.py` 의 `THEMES` |
| 한 곳만 급히 고치기 | Supabase Table Editor 에서 직접 수정 (다음에 도구를 실행하면 덮어쓰이므로 표에도 반영) |

같은 원본(`source`, `source_id`)은 다시 넣어도 한 줄로 유지됩니다. 지우는 기능은 없으므로, 없어진 곳은 Table Editor 에서 지웁니다.

## 고치기 — "이걸 바꾸려면 어디를"

| 바꾸려는 것 | 고치는 곳 |
|---|---|
| 서비스 이름·문구 | `web/src/lib/brand.ts`, `app/lib/brand.dart` |
| 색·모서리·글꼴 | `web/src/app/globals.css` 의 `@theme`, `app/lib/theme.dart` |
| 테마·지역·분류 목록 | `api/constants.py` (화면은 `/meta` 로 받아 씀) |
| AI 의 역할과 말투 | `api/services/plan_ai.py` 의 `SYSTEM_PROMPT` |
| AI 가 쓰는 도구 | `api/services/plan_ai.py` 의 `ask_gemini` 안 함수들 |
| 규칙 방식의 동선·하루 개수 | `api/services/plan_rule.py` 의 `AREA_ORDER`, `SIGHTS_PER_DAY`, `COMPANION_THEMES` |
| 날씨를 보는 지점 | `api/services/weather.py` 의 `PLACES` |
| 새 주소 추가 | `docs/api.md` → `api/routers/` → `web/src/lib/api.ts` → `app/lib/api/api_client.dart` |
| 새 화면 추가 | 웹 `web/src/app/<이름>/page.tsx` + 메뉴(`brand.ts`), 앱 `app/lib/screens/` + 탭(`home_shell.dart`) |
| DB 칸 추가 | `supabase/migrations/` 에 새 번호의 SQL → `api/schemas.py` → `docs/api.md` → 화면 타입 |

### 고치는 순서

1. 브랜치를 새로 만든다. (`git switch -c fix/…`)
2. 테스트를 먼저 쓰고 실패를 확인한다.
3. 고친다. 검사를 돌린다. (VS Code 의 "검사: …" 작업)
4. 로컬에서 실제로 켜서 본다. ("서버 + 웹 함께 실행", 실측 점검)
5. 커밋 메시지에 무엇을 확인했는지 적고 푸시한다.
6. `main` 에 합치면 Vercel 이 자동으로 다시 배포한다. `/status` 와 실측 점검으로 확인한다.

DB 구조를 바꾸는 변경은 **SQL 을 먼저 실행**하고 그다음 코드를 배포합니다. 순서가 바뀌면 새 코드가 없는 칸을 찾다가 오류를 냅니다.

### 되돌리기

배포한 뒤 문제가 생기면 Vercel → Deployments 에서 직전 배포를 골라 **Promote to Production**(또는 Rollback)을 누릅니다. 코드는 그 뒤에 천천히 고칩니다.

## 사고 대응

### 비밀 키를 실수로 올렸을 때

키가 든 파일을 지우는 커밋을 올려도 **기록에는 남습니다.** 지우는 것이 아니라 **키를 새로 발급**해야 합니다.

1. 해당 서비스에서 키를 폐기하고 새로 만든다. (Supabase: Project Settings → API / Google AI Studio / 공공데이터포털)
2. `api/.env` 와 Vercel 환경변수를 새 값으로 바꾸고 서버를 다시 배포한다.
3. `/status` 와 실측 점검으로 확인한다.

예방: `.env`, `.env.local`, `env.json` 은 `.gitignore` 로 막혀 있습니다. GitHub 저장소 Settings 의 Secret scanning push protection 을 켜 두면 올리는 순간 막아 줍니다.

### 무료 한도에 걸렸을 때

| 증상 | 대응 |
|---|---|
| AI 일정이 "간단 추천"으로만 나옴 | AI 한도. 규칙 방식으로 계속 동작하므로 서비스는 유지됨. 한도는 시간이 지나면 풀림 |
| DB 가 응답하지 않음 | Supabase 프로젝트가 일시 정지됨. 대시보드에서 다시 켬 |
| TourAPI 가 오류를 냄 | 하루 호출 한도. 다음 날 다시 실행. 화면은 DB 를 보므로 영향 없음 |

### 외부 서비스가 멈췄을 때

| 멈춘 것 | 화면에서 보이는 것 |
|---|---|
| 날씨 (Open-Meteo) | 날씨 배너에 안내만 뜨고, 추천 목록과 나머지는 정상. 일정은 날씨 없이 짬 |
| AI (Gemini) | 20초 안에 답이 없으면 규칙 방식으로 넘어감 ("간단 추천" 표시) |
| DB (Supabase) | 목록·상세가 오류 안내와 "다시 시도" 버튼을 보여 줌 |
| 지도 타일 (OpenStreetMap) | 지도 바탕만 비고 나머지는 정상 |

## 정기적으로 할 일

| 주기 | 할 일 |
|---|---|
| 배포할 때마다 | `/status`, 실측 점검 |
| 주 1회 | Supabase 가 정지되지 않았는지, 각 서비스 사용량 |
| 월 1회 | TourAPI 데이터 다시 받기, AI 모델 이름이 아직 유효한지(`GEMINI_MODEL`) |
| 키를 바꿨을 때 | Vercel 환경변수 → 다시 배포 → 확인 |

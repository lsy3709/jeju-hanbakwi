# AI 코딩 도구에게 주는 프로젝트 규칙

이 저장소에서 코드를 만들거나 고칠 때 아래를 지켜 주세요.

## 구조

- `web/`(Next.js) 와 `app/`(Flutter) 은 화면만 담당합니다. 데이터는 **반드시 `api/`(FastAPI)의 주소를 불러서** 얻습니다.
- 화면 코드에서 Supabase 테이블을 직접 읽거나 쓰지 않습니다. Supabase 는 화면에서 **구글 로그인에만** 씁니다.
- 화면 코드에서 AI(Gemini)나 외부 API(TourAPI, Open-Meteo)를 직접 부르지 않습니다.
- 서버의 주소·응답 모양을 바꾸면 `docs/api.md` 를 먼저 고치고, 웹과 앱을 함께 맞춥니다.

## 비밀 값

- 비밀 키(`SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, `TOUR_API_KEY`)는 `api/.env` 에만 둡니다.
- 키를 코드·문서·테스트·커밋 메시지에 적지 않습니다. `NEXT_PUBLIC_` 으로 시작하는 변수에 비밀 값을 넣지 않습니다.
- `.env`, `.env.local`, `env.json` 은 git 에 올리지 않습니다. 새 변수를 만들면 `*.example` 파일에 이름만 추가합니다.

## 서버 (api)

- 층을 지킵니다: `routers/`(주소 — 받아 넘기고 돌려주기만) → `services/`(일) → `repo.py`(DB). 주소 파일에 계산이나 DB 질의를 직접 쓰지 않습니다. 자세한 것은 `docs/architecture.md`.
- DB 는 `repo.py` 의 함수로만 다룹니다. 다른 파일에서 Supabase 클라이언트를 직접 쓰지 않습니다.
- 일정 짜는 방식을 더할 때는 `services/plan_common.py` 의 `Planner` 모양(`name`, `plan(request)`)을 따르는 클래스를 만들고 `services/planner.py` 의 `choose_planners` 에 넣습니다.
- 데이터 분류가 틀린 곳은 규칙을 복잡하게 만들지 말고 `transform.py` 의 `CORRECTIONS` 표에 한 줄 더합니다.
- 로그인이 필요한 주소는 `Depends(get_current_user)` 로 확인한 `user.id` 만 씁니다. 요청 본문이나 쿼리로 받은 사용자 ID 를 믿지 않습니다.
- `favorites`, `trips` 를 다루는 질의에는 항상 `user_id` 조건을 붙입니다. (서버는 비밀 키로 접속해 RLS 를 건너뜁니다)
- 일정에는 DB 에 있는 관광지만 넣습니다. AI 가 지어낸 장소는 버립니다.
- 고친 뒤 `pytest` 가 모두 통과해야 합니다. 기능을 더하면 테스트도 더합니다.

## 화면 (web, app)

- 층을 지킵니다. 웹: `app/`(화면 조립) → `hooks/`(상태·불러오기) → `lib/api.ts`(서버). 앱: `screens/`(화면) → `controllers/`(상태) → `api/api_client.dart`(서버). 화면 파일에서 `fetch` 나 `http` 를 직접 부르지 않습니다.
- 계산은 순수 함수(`lib/*.ts`, `format.dart`)나 컨트롤러로 빼서 화면 없이 테스트합니다.
- 색·모서리·글꼴은 `docs/design.md` 의 토큰을 쓰고, 값은 `globals.css` / `theme.dart` 한 곳에서만 정의합니다.
- 서비스 이름과 문구는 `brand.ts` / `brand.dart` 에 둡니다.
- 불러오는 중 · 결과 없음 · 오류 상태를 항상 만듭니다. 서버가 꺼져 있어도 화면이 죽지 않아야 합니다.
- web: `npm run lint`, `npx tsc --noEmit`, `npm test`, `npm run build` / app: `flutter analyze`, `flutter test` 가 통과해야 합니다.

## 일하는 순서

- 기능 하나씩 진행합니다. 서버 기능과 화면(웹·앱)은 따로 작업합니다.
- 기능마다 단위 테스트 → 로컬에서 실제 실행 → 화면 확인을 마친 뒤에만 커밋하고 푸시합니다.
- 커밋 메시지에 무엇을 확인했는지 적고, `docs/CHECKLIST.md` 의 표를 갱신합니다.
- 확인하지 못한 것은 ⏳ 로 남기고 이유를 적습니다. 확인하지 않은 것을 ✅ 로 적지 않습니다.

## 글

- 화면 문구, 주석, 커밋 메시지는 한국어로 씁니다. 주석은 "무엇"보다 "왜"를 적습니다.
- 초보자가 읽는 교재입니다. 파일은 작게, 이름은 분명하게, 꼭 필요한 라이브러리만 씁니다.

# 구조와 설계 — 제주 한 바퀴

이 문서는 "어디에 무엇이 있고, 왜 그렇게 나눴는지"를 설명합니다.
코드를 고치기 전에 한 번 읽으면, 고칠 곳을 찾는 시간이 줄어듭니다.

## 한눈에

```
[web  Next.js] ─┐                     ┌─ Supabase (PostgreSQL · 구글 로그인)
                ├─→ [api  FastAPI] ───┼─ Gemini (AI 일정)
[app  Flutter] ─┘                     └─ Open-Meteo (날씨)

[api/tools/sync_spots.py]  한국관광공사 TourAPI → 우리 기준으로 고치기 → DB 에 넣기
```

화면(web, app)은 서버(api)만 부르고, 서버만 DB·AI·외부 서비스를 부릅니다.
이 한 방향 흐름이 이 프로젝트의 가장 중요한 규칙입니다.

| 왜 이렇게 하나 | 지키지 않으면 |
|---|---|
| 비밀 키가 서버에만 있다 | 화면 코드에 키가 들어가 누구나 볼 수 있게 된다 |
| 웹과 앱이 같은 주소를 쓴다 | 같은 기능을 웹용·앱용으로 두 번 만든다 |
| "누구의 데이터인가"를 서버 한 곳에서 판단한다 | 화면마다 판단이 달라져 남의 데이터가 보인다 |

## 층 나누기

세 폴더 모두 같은 생각으로 나눴습니다: **보여 주는 곳 / 상태와 흐름을 정하는 곳 / 바깥과 통하는 곳.**

| 층 | 서버 `api/` | 웹 `web/src/` | 앱 `app/lib/` |
|---|---|---|---|
| 바깥에서 들어오는 곳 | `routers/` 주소 | `app/` 화면 | `screens/` 화면 |
| 일을 하는 곳 | `services/` | `hooks/` | `controllers/` |
| 바깥으로 나가는 곳 | `repo.py`(DB), `services/weather.py`, `services/plan_ai.py` | `lib/api.ts`(서버) | `api/api_client.dart`(서버) |
| 여러 곳이 함께 쓰는 것 | `schemas.py`, `constants.py`, `config.py`, `deps.py` | `lib/types.ts`, `lib/format.ts`, `lib/brand.ts`, `components/` | `models/`, `format.dart`, `brand.dart`, `theme.dart`, `widgets/` |

규칙은 "위에서 아래로만 부른다"입니다. 화면이 훅을 부르고 훅이 `api.ts` 를 부릅니다. `api.ts` 가 화면을 부르는 일은 없습니다.

### 서버 `api/`

```
main.py            앱을 만들고 주소 묶음을 끼우는 곳 (조립만)
routers/           주소 — 요청을 받아 넘기고 결과를 돌려주기만 함
  system.py          /health, /status
  spots.py           /meta, /spots, /spots/{id}
  weather.py         /weather
  agent.py           /agent/plan
  me.py              /me, /me/favorites, /me/trips   (로그인 필요)
services/          일
  planner.py         일정 짜기의 입구 (어떤 방식을 어떤 순서로 시도할지)
  plan_ai.py         AI 방식
  plan_rule.py       규칙 방식
  plan_common.py     두 방식이 함께 쓰는 것 (날짜, 날씨 찾기)
  weather.py         날씨 받아 오기
  photos.py          사진 주소 완성하기
repo.py            DB — 다른 파일은 DB 를 직접 만지지 않음
auth.py            로그인 확인
deps.py            주소들이 함께 쓰는 "주입할 것"
schemas.py         주고받는 자료의 모양 (docs/api.md 와 같아야 함)
constants.py       테마·지역·분류 목록
config.py          환경변수(.env) 읽기
transform.py       외부 데이터 한 건 → 우리 DB 한 줄
tools/             명령줄 도구 (데이터 넣기, 실측 점검, 예시 데이터)
tests/             테스트 (fakes.py = 가짜 DB)
```

## 쓰인 설계 패턴

"패턴"은 자주 만나는 문제에 붙은 이름입니다. 이름을 알면 코드를 설명하고 찾기가 쉬워집니다.

| 패턴 | 어디에 | 풀려는 문제 |
|---|---|---|
| **저장소(Repository)** | `api/repo.py` | DB 를 여기저기서 직접 부르면, DB 가 바뀔 때 고칠 곳이 흩어진다. 한 파일에 모아 두면 그 파일만 고치면 되고, 테스트에서는 가짜(`tests/fakes.py`)로 통째로 바꿀 수 있다 |
| **의존성 주입(Dependency Injection)** | `api/deps.py`, 주소의 `Depends(...)` | 주소가 DB·날씨·로그인을 직접 만들면 테스트할 수 없다. "필요한 것"만 적고 실제로 줄 것은 밖에서 정한다 |
| **전략(Strategy)** | `api/services/planner.py` + `plan_ai.py` · `plan_rule.py` | 일정 짜는 방식이 둘이다. `plan(request)` 라는 같은 모양으로 맞춰 두면, 입구는 방식을 몰라도 차례로 시도할 수 있다. 새 방식을 더할 때 기존 코드를 고치지 않는다 |
| **어댑터(Adapter)** | `api/transform.py`, `api/services/weather.py` | 바깥 서비스의 자료 모양은 우리 것과 다르다. 경계에서 한 번 바꿔 두면, 안쪽 코드는 우리 모양만 알면 된다 |
| **퍼사드(Facade)** | `web/src/lib/api.ts`, `app/lib/api/api_client.dart` | 화면마다 주소·헤더·오류 처리를 따로 쓰면 틀리기 쉽다. "서버와 통하는 유일한 문"을 하나 두고 화면은 그 함수만 부른다 |
| **관찰자(Observer)** | 앱의 `ChangeNotifier` + `ListenableBuilder`, 웹의 `AuthProvider`(`onAuthStateChange`) | 로그인 상태나 찜 목록이 바뀌면 여러 화면이 따라 바뀌어야 한다. 바뀐 쪽이 알리고, 보는 쪽이 듣는다 |
| **화면과 상태의 분리** | 웹 `hooks/`, 앱 `controllers/` | 화면 파일에 그리기와 상태 로직이 섞이면 길어지고 테스트할 수 없다. 상태를 빼내면 화면 없이도 테스트한다 |
| **대체 경로(Fallback)** | `planner.plan_trip`, 사진의 대체 그림, 날씨 실패 시 추천 유지 | 바깥 서비스는 언젠가 실패한다. 실패해도 줄 수 있는 답을 미리 정해 둔다 |

### 예: 일정 짜는 방식을 하나 더하려면

1. `services/plan_xxx.py` 에 `name` 과 `plan(request)` 를 가진 클래스를 만든다 (`plan_common.Planner` 모양).
2. `services/planner.py` 의 `choose_planners` 에 한 줄 더한다.
3. `tests/test_plan_strategies.py` 의 "결과 모양이 같다" 테스트에 그 클래스를 넣는다.

주소(`routers/agent.py`)와 화면은 고칠 필요가 없습니다.

## 자료가 흐르는 길

### 관광지 목록을 볼 때

```
화면  →  api.ts / api_client.dart  →  GET /spots  →  routers/spots.py
                                                        → repo.list_spots()      (DB)
                                                        → photos.with_photo_addresses()
화면  ←  { items, total, page, size }
```

### 일정을 짤 때

```
화면 → POST /agent/plan → routers/agent.py → planner.plan_trip()
        ① AiPlanner.plan()   AI 가 search_spots · get_weather 도구를 스스로 부름
                             → 답을 검사(우리 DB 에 있는 곳만, 시간 순 정렬)
           실패(키 없음 · 한도 · 20초 초과 · 이상한 답)하면 ↓
        ② RulePlanner.plan() 같은 DB 와 날씨로 규칙에 따라 짬
화면 ← { mode: "ai" | "rule", answer, itinerary, sources }
```

### 로그인이 필요한 요청

```
화면: Supabase 로 구글 로그인 → 액세스 토큰을 받음
화면 → GET /me/favorites  (Authorization: Bearer 토큰)
        → auth.get_current_user()  Supabase 에 "이 토큰 주인이 누구냐" 확인
        → repo.list_favorites(user.id)   확인된 ID 로만 조회
```

화면이 보낸 사용자 ID 는 받지 않습니다. 서버가 확인한 ID 만 씁니다.

## 테스트 전략

| 무엇을 | 어떻게 | 어디에 |
|---|---|---|
| 순수한 계산 (변환, 날짜, 문구) | 입력을 넣고 결과를 비교 | `api/tests/test_transform*.py`, `web/src/lib/*.test.ts`, `app/test/format_test.dart` |
| 주소의 약속 | 가짜 DB 를 끼우고 주소를 불러 봄 | `api/tests/test_api.py`, `test_status.py` |
| 바깥 서비스를 부르는 곳 | 가짜 연결을 끼워 "무엇을 어떻게 불렀나"를 확인 | `api/tests/test_outside_calls.py` |
| 화면 상태 | 화면 없이 훅의 순수 함수·컨트롤러를 테스트 | `web/src/lib/*.test.ts`, `app/test/*_controller_test.dart` |
| 진짜로 연결됐는지 | 켜져 있는 서버를 실제로 부름 | `api/tools/check_live.py` (실측 점검) |

테스트가 가짜를 끼울 수 있는 것은 위의 저장소·의존성 주입·퍼사드 덕분입니다. 구조와 테스트는 한 묶음입니다.

## 고칠 때 지키는 것

1. 주소나 응답 모양을 바꾸면 **`docs/api.md` 를 먼저** 고치고, 서버 → 웹 → 앱 순으로 맞춘다.
2. 새 기능은 **테스트를 먼저** 쓰고 실패를 확인한 뒤 만든다.
3. DB 는 `repo.py`, 서버 호출은 `api.ts` / `api_client.dart` 로만.
4. 고친 뒤 검사가 모두 통과해야 한다 (VS Code 의 "검사: …" 작업).
5. 확인한 것과 못 한 것을 `docs/CHECKLIST.md` 에 적는다.

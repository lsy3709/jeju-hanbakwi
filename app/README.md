# 제주 한 바퀴 — 앱 (Flutter)

날씨와 취향에 맞는 제주 관광지를 찾아보는 Flutter 앱입니다. 홈·탐색(목록/지도)·관광지 상세 화면이 있습니다.

## 실행 방법

```bash
flutter pub get
cp env.example.json env.json        # Windows PowerShell 은 copy 를 쓰세요
flutter run --dart-define-from-file=env.json                 # 안드로이드 에뮬레이터
flutter run -d chrome --dart-define-from-file=env.json       # 크롬
```

## 설정 값 (`env.json`)

- `API_URL`: 서버(FastAPI) 주소. 안드로이드 에뮬레이터에서는 `http://10.0.2.2:8000`, 크롬에서는 `http://localhost:8000` 을 씁니다.

## 검사 명령

```bash
flutter analyze   # 정적 분석
flutter test      # 단위·위젯 테스트
```

## 폴더 안내 (`lib/`)

화면은 "그리기"만, 상태와 데이터 불러오기는 "컨트롤러"가 맡습니다. 컨트롤러는 위젯 없이 `test/controllers/` 에서 단위 테스트합니다.

| 폴더·파일 | 하는 일 |
|---|---|
| `main.dart`, `app.dart` | 앱 시작점과 기본 틀(테마, 첫 화면). `app_scope.dart` 는 화면 어디서든 api·탭 이동을 꺼내 쓰는 통로 |
| `screens/` | 화면. 홈·탐색·관광지 상세. `home_shell.dart` 가 하단 탭 2개(홈·탐색, 넓은 화면은 왼쪽 메뉴)를 맡음 |
| `controllers/` | 화면 상태를 가진 `ChangeNotifier`: `explore_controller`(검색 조건·목록·더 보기), `home_controller`(날씨·추천) |
| `widgets/` | 여러 화면이 쓰는 작은 위젯: 관광지 카드, 지도, 필터 메뉴, 날씨 배너, 상태 화면 등 |
| `models/` | 서버 응답을 담는 데이터 모양(관광지, 날씨) |
| `api/api_client.dart` | 서버와 통하는 **유일한 문**. 화면과 컨트롤러는 http 를 직접 부르지 않음 |
| `config.dart`, `brand.dart`, `theme.dart` | 설정 값 읽기 / 서비스 이름·문구 / 색·모서리 |

화면 하나의 흐름: `screens/*` 가 컨트롤러를 만들고 → 컨트롤러가 `api_client` 로 서버를 부르고 → `ListenableBuilder` 가 컨트롤러가 바뀔 때마다 화면을 다시 그립니다.

## 이걸 바꾸려면 어디를 고치나

| 바꾸고 싶은 것 | 고칠 곳 |
|---|---|
| 서비스 이름, 화면 문구(인사말, 검색창 안내 등) | `lib/brand.dart` |
| 브랜드 색, 모서리 둥글기 | `lib/theme.dart` (`AppColors`, `AppRadius`) — 값은 이 한 곳에서만 정의 |
| 하단 탭(이름·아이콘·순서) | `lib/screens/home_shell.dart` 의 `_tabs` 와 `IndexedStack` 의 화면 순서 |
| 화면에 직접 쓰인 글(버튼, 안내 문구) | 해당 `lib/screens/*.dart` 또는 `lib/widgets/*.dart` |
| 서버 주소 | `env.json` (`API_URL`). 읽는 곳은 `lib/config.dart` |
| 새 화면 추가 | ① `lib/screens/` 에 화면 파일 ② 상태·불러오기가 있으면 `lib/controllers/` 에 컨트롤러(+ `test/controllers/` 테스트) ③ 탭이면 `home_shell.dart` 에 등록, 아니면 `Navigator.push` (상세 화면은 `SpotDetailScreen.open`) |
| 새 API 메서드 추가 | ① `docs/api.md` 에 주소·응답 적기 ② `lib/models/` 에 응답 모양 ③ `lib/api/api_client.dart` 에 메서드 ④ 컨트롤러에서 호출 ⑤ `test/api_client_test.dart` 에 시험 |
| 관광지 상세 화면으로 이동 | 어디서든 `SpotDetailScreen.open(context, spotId: ..., initial: ...)` |

전체 설명은 저장소 루트 README 참고.

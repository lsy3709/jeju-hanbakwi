# 제주 한 바퀴 — 앱 (Flutter)

날씨와 취향에 맞는 제주 관광지를 찾고, AI가 일자별 여행 일정을 짜 주는 Flutter 앱입니다.

## 실행 방법

```bash
flutter pub get
cp env.example.json env.json        # Windows PowerShell 은 copy 를 쓰세요
flutter run --dart-define-from-file=env.json                 # 안드로이드 에뮬레이터
flutter run -d chrome --dart-define-from-file=env.json       # 크롬
```

## 설정 값 (`env.json`)

- `API_URL`: 서버(FastAPI) 주소. 안드로이드 에뮬레이터에서는 `http://10.0.2.2:8000`, 크롬에서는 `http://localhost:8000` 을 씁니다.
- `SUPABASE_URL`: Supabase 프로젝트 주소. 로그인에만 씁니다. 비워 두면 로그인 버튼 대신 안내가 나옵니다.
- `SUPABASE_ANON_KEY`: Supabase 공개(anon) 키. 로그인에만 씁니다.

## 검사 명령

```bash
flutter analyze   # 정적 분석
flutter test      # 단위·위젯 테스트
```

## 폴더 안내 (`lib/`)

- `main.dart`: 앱 시작점입니다. `app.dart` 가 앱의 기본 틀(테마, 첫 화면)을 맡습니다.
- `screens/`: 화면입니다. 홈(`home_screen.dart`, `home_shell.dart` 가 하단 탭을 담당), 탐색, AI 플래너, 내 여행, 관광지 상세.
- `widgets/`: 화면에서 함께 쓰는 조각(관광지 카드, 지도, 일정 보기, 로그인 안내, 상태 화면 등)입니다.
- `models/`: 서버 응답을 담는 데이터 모양(관광지, 일정, 여행, 날씨)입니다.
- `api/`: 서버 호출(`api_client.dart`)입니다.
- `auth/`: 구글 로그인(`auth_service.dart`)과 찜 목록 저장(`favorites_store.dart`)입니다.
- `config.dart`: `env.json` 값을 읽는 곳입니다.

## 브랜드를 바꿀 때 고칠 파일

- `lib/brand.dart`: 서비스 이름과 화면 문구
- `lib/theme.dart`: 색상 등 디자인 토큰 (`AppColors`)

전체 설명은 저장소 루트 README 참고.

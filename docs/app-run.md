# 앱 실행하기 — 크롬 · 에뮬레이터 · 실제 폰

Flutter 앱(`app/`)을 켜는 방법을 처음부터 따라 할 수 있게 적었습니다.
README 의 [4. 앱](../README.md#4-앱-app) 을 자세히 풀어 쓴 문서입니다.

| 어디서 켜나 | 언제 쓰나 | 서버 주소(앱이 부르는 곳) |
|---|---|---|
| **크롬** | 설치 없이 화면을 빨리 볼 때 | `http://localhost:8000` |
| **에뮬레이터** | 진짜 안드로이드 앱처럼 볼 때 (수업 기본) | `http://10.0.2.2:8000` |
| **실제 폰(USB)** | 내 폰으로 볼 때 | `http://<내 PC 의 IP>:8000` |

> **서버 주소는 신경 쓰지 않아도 됩니다.** `env.json` 의 `API_URL` 이 `http://10.0.2.2:8000`(처음 그대로)이면,
> 에뮬레이터에서는 그 주소를, 크롬에서는 알아서 `http://localhost:8000` 을 부릅니다(`app/lib/config.dart` 의 `resolveApiUrl`).
> 직접 바꿔야 하는 경우는 **실제 폰**과 **배포 서버**에 붙일 때뿐입니다.

---

## 0. 먼저 — 서버가 켜져 있는지

앱은 서버(api)가 없으면 "서버에 연결할 수 없어요"만 보여 줍니다. 앱보다 **서버를 먼저** 켭니다.

```powershell
cd api
.venv\Scripts\activate
uvicorn main:app --reload
```

브라우저에서 `http://localhost:8000/status` 를 열어 `"database":"ok"` 와 `"spots":68` 같은 글자가 보이면 됩니다.
(로컬 DB 를 쓰는 날은 그 전에 Docker 로 DB 를 켭니다 — [시작하는 방법](start.md#매일-다시-켜는-순서))

## 1. 처음 한 번 — 앱 설정 파일

```powershell
cd app
flutter pub get
copy env.example.json env.json
```

`env.json` 은 git 에 올라가지 않는 내 설정 파일입니다. 로그인까지 볼 때만 `SUPABASE_URL` 과 `SUPABASE_ANON_KEY`(공개 키)를 채웁니다. 비워 두면 로그인 버튼 대신 안내 문구가 나오고, 나머지 화면은 그대로 됩니다.

설치가 제대로 됐는지는 이 명령으로 봅니다.

```powershell
flutter doctor
```

`Flutter` · `Android toolchain` · `Chrome` · `Android Studio` 줄이 `[√]` 이면 됩니다.
`Some Android licenses not accepted` 가 나오면 `flutter doctor --android-licenses` 를 실행하고 물을 때마다 `y` 를 누릅니다.

---

## 2. 크롬으로 실행 (가장 빠름)

```powershell
cd app
flutter run -d chrome --dart-define-from-file=env.json
```

- 크롬 창이 새로 열리고 1 ~ 2분 뒤 홈 화면이 나옵니다. 처음 한 번은 더 오래 걸립니다.
- VS Code 에서는 `Ctrl+Shift+P` → `Tasks: Run Task` → **3. 앱 실행 - 크롬 (app)**.
- 터미널에서 `r` = 고친 화면 반영, `R` = 처음부터 다시, `q` = 끝내기.

> 크롬 실행은 "웹 화면"이라 안드로이드에만 있는 것(구글 로그인 뒤 앱으로 돌아오기, 기기 보안 저장소)은 에뮬레이터와 조금 다르게 동작합니다. 화면 확인용으로 씁니다.

---

## 3. 에뮬레이터 — Android Studio 로 처음 한 번 만들기

에뮬레이터는 PC 안에서 도는 가상의 안드로이드 폰입니다. **Android Studio 는 에뮬레이터를 만들 때만** 쓰고, 코드는 VS Code 에서 씁니다.
(아래 메뉴 이름은 Android Studio 2025.1 기준입니다. 판에 따라 글자가 조금 다를 수 있습니다.)

### 3-1. Android Studio 설치와 SDK

1. https://developer.android.com/studio 에서 받아 설치합니다. 설치 마법사는 기본값(Standard)으로 진행하면 Android SDK · 에뮬레이터가 함께 깔립니다.
2. 처음 켜면 Welcome 화면이 나옵니다. **More Actions → SDK Manager** 를 엽니다.
   - **SDK Platforms** 탭: 최신 Android(예: Android 16 / API 36) 하나에 체크되어 있는지 봅니다.
   - **SDK Tools** 탭: 아래 네 가지에 체크하고 **Apply** 합니다.
     - Android SDK Build-Tools
     - **Android SDK Command-line Tools (latest)** ← 빠지면 `flutter doctor` 가 라이선스 오류를 냅니다
     - Android Emulator
     - Android SDK Platform-Tools
   - 창 위쪽의 **Android SDK Location** 경로를 적어 둡니다(기본 `C:\Users\<이름>\AppData\Local\Android\Sdk`). 아래 명령에서 씁니다.
3. 터미널에서 `flutter doctor --android-licenses` → 모두 `y`.

### 3-2. 가상 기기(AVD) 만들기

1. Welcome 화면에서 **More Actions → Virtual Device Manager** 를 엽니다.
   (프로젝트 창이 열려 있으면 **View → Tool Windows → Device Manager**, 또는 오른쪽 세로 막대의 폰 모양 아이콘)
2. **+** (Create Virtual Device) 를 누릅니다.
3. **Phone** 에서 기기 하나를 고릅니다. 예: **Medium Phone** 또는 **Pixel 8** → **Next**.
4. 설정 화면:
   - **Name**: 영문으로 짧게. 예: `Pixel_8` (명령에서 이 이름을 씁니다. 띄어쓰기는 `_` 로 바뀝니다)
   - **API**: 최신 것(예: API 36)
   - **Services**: **Google Play Store** (구글 로그인 확인에 필요한 크롬이 들어 있는 이미지)
   - **System Image**: 목록에서 `x86_64` 이미지 옆의 **다운로드(↓)** 를 눌러 받습니다(1 ~ 2GB, 몇 분 걸림)
   - 그 밖의 값은 기본 그대로 → **Finish**
5. Device Manager 목록에 생긴 기기의 **▶(Run)** 를 눌러 한 번 켜 봅니다. 폰 화면이 나오고 잠금 화면 · 홈 화면까지 가면 성공입니다.

> 에뮬레이터가 "가상화를 켜라(Hypervisor / HAXM / WHPX)"는 오류로 켜지지 않으면: BIOS 에서 가상화(Intel VT-x / AMD-V, SVM)를 켜고,
> Windows 검색 → "Windows 기능 켜기/끄기" → **Windows 하이퍼바이저 플랫폼** 에 체크 → 재부팅합니다.

만든 뒤에는 Android Studio 를 닫아도 됩니다.

---

## 4. 에뮬레이터로 실행

순서: **에뮬레이터 켜기 → 켜졌는지 확인 → 앱 실행**.

### 방법 A. VS Code 에서 (마우스로)

1. VS Code 에서 저장소 폴더를 엽니다(Flutter 확장이 설치되어 있어야 함).
2. 오른쪽 아래 상태 막대의 기기 이름(처음엔 `Chrome` 이나 `No Device`)을 누릅니다 → 위쪽에 뜨는 목록에서 내가 만든 에뮬레이터(예: `Pixel_8 mobile emulator`)를 고릅니다. 에뮬레이터 창이 켜집니다.
3. `F5` (실행 및 디버그 → **앱 실행 (Flutter)**) 또는 `Ctrl+Shift+P` → `Tasks: Run Task` → **3. 앱 실행 - 에뮬레이터 (app)**.

### 방법 B. 명령어로

```powershell
flutter emulators                         # 만들어 둔 에뮬레이터 이름 보기
flutter emulators --launch Pixel_8        # 켜기 (이름은 내 것으로)
flutter devices                           # 켜졌는지 확인 — emulator-5554 같은 줄이 보이면 됨
cd app
flutter run --dart-define-from-file=env.json
```

에뮬레이터가 켜지는 데 1 ~ 2분 걸립니다. `flutter devices` 에 안 보이면 조금 기다렸다 다시 봅니다.
기기가 여러 개(크롬 · 에뮬레이터)면 `flutter run` 이 고르라고 묻습니다. 바로 정하려면 `-d emulator-5554` 를 붙입니다.

### 방법 C. 에뮬레이터를 직접 켜기 (잘 안 켜질 때)

`flutter emulators --launch` 로 켰는데 창이 떴다가 바로 사라지면, 저장된 상태를 쓰지 않고 새로 부팅합니다.

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -list-avds
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_8 -no-snapshot -gpu swiftshader_indirect
```

- SDK 를 다른 곳에 깔았다면 `$env:LOCALAPPDATA\Android\Sdk` 를 3-1 에서 적어 둔 경로로 바꿉니다.
- 이 터미널은 에뮬레이터가 켜져 있는 동안 그대로 둡니다. 앱은 **새 터미널**에서 `flutter run` 합니다.
- 매번 긴 경로를 치기 싫으면 Windows 환경 변수 `Path` 에 `<SDK 경로>\emulator` 와 `<SDK 경로>\platform-tools` 를 추가하고 터미널을 새로 엽니다. 그 뒤로는 `emulator -avd Pixel_8 ...`, `adb devices` 로 됩니다.

### 실행된 뒤

- 첫 빌드는 3 ~ 5분 걸립니다(Gradle 이 필요한 것을 받음). 두 번째부터는 빨라집니다.
- 터미널에서 `r` = 고친 화면 반영(핫 리로드), `R` = 처음부터 다시, `q` = 끝내기.
- 홈에 날씨와 "지금 가기 좋은 곳" 카드가 나오면 서버와 연결된 것입니다. 사진은 내 PC 서버(`10.0.2.2:8000/photos/...`)에서 옵니다.

---

## 5. 실제 안드로이드 폰 (USB)

> 이 방법은 실제 폰으로는 아직 확인하지 못했습니다. 막히면 에뮬레이터나 크롬을 씁니다.

1. 폰: **설정 → 휴대전화 정보 → 소프트웨어 정보 → 빌드번호** 를 7번 누르면 "개발자 모드"가 켜집니다.
2. 폰: **설정 → 개발자 옵션 → USB 디버깅** 켜기 → USB 로 PC 에 연결 → 폰에 뜨는 "USB 디버깅 허용"에서 **허용**.
3. `flutter devices` 에 폰 이름이 보이는지 확인합니다.
4. 폰에서는 `10.0.2.2` 도 `localhost` 도 내 PC 가 아닙니다. **PC 와 폰을 같은 와이파이**에 두고 PC 의 IP 를 씁니다.
   - PC 의 IP: `ipconfig` → 와이파이 어댑터의 `IPv4 주소` (예: `192.168.0.10`)
   - 서버를 밖에서도 받게 켭니다: `uvicorn main:app --reload --host 0.0.0.0`
   - Windows 방화벽이 물으면 "개인 네트워크" 허용
5. 실행 (env.json 은 그대로 두고 주소만 명령에서 바꿈):

```powershell
cd app
flutter run --dart-define-from-file=env.json --dart-define=API_URL=http://192.168.0.10:8000
```

---

## 6. 배포한 서버에 붙여 보기

로컬 서버 대신 Vercel 에 올린 서버를 부를 때는 주소만 바꿉니다.

```powershell
flutter run -d chrome --dart-define-from-file=env.json --dart-define=API_URL=https://<내 서버>.vercel.app
```

크롬 실행에서 배포 서버를 부르면 서버의 `ALLOWED_ORIGINS` 에 걸릴 수 있습니다(크롬 실행 주소는 `http://localhost:<아무 포트>` — 로컬 서버는 이 주소를 받아 주도록 되어 있음). 설치 파일(APK)을 만들어 폰에 넣는 방법은 [시작하는 방법 A](start.md#앱--배포-서버에-붙여-설치하기)에 있습니다.

---

## 3D 지도 (탐색 → 3D)

앱의 3D 지도는 **웹에서 만든 화면(`/embed/map3d`)을 웹뷰로 띄운 것**입니다. 그래서 서버와 함께 **웹도 켜져 있어야** 보입니다.

```bash
cd web
npm run dev
```

웹 주소는 `env.json` 의 `WEB_URL` 에서 읽습니다. 규칙은 `API_URL` 과 같습니다 — `http://10.0.2.2:3000`(처음 그대로)이면
에뮬레이터는 그 주소를, 크롬은 `http://localhost:3000` 을 엽니다. 배포한 웹을 쓰려면 `https://<내 웹>.vercel.app` 으로 바꿉니다.

---

## 7. 막힐 때

| 증상 | 원인 | 해결 |
|---|---|---|
| 3D 를 눌렀는데 빈 화면이거나 "연결할 수 없음" | 웹(Next.js)이 꺼져 있거나 `WEB_URL` 이 틀림 | `http://localhost:3000/embed/map3d` 가 브라우저에서 열리는지 보고, `env.json` 의 `WEB_URL` 확인 |
| "서버에 연결할 수 없어요" (모든 환경) | 서버가 꺼져 있음 | `http://localhost:8000/status` 가 열리는지 보고, 안 열리면 서버부터 켭니다 |
| 크롬 실행에서만 "서버에 연결할 수 없어요" | 옛 코드(이 수정 전)는 `env.json` 의 `10.0.2.2` 를 크롬에서도 그대로 불렀음 | 최신 `main` 을 받거나, `flutter run -d chrome ... --dart-define=API_URL=http://localhost:8000` |
| 에뮬레이터에서만 "서버에 연결할 수 없어요" | `API_URL` 을 `localhost` 로 바꿔 둠 | `env.json` 의 `API_URL` 을 `http://10.0.2.2:8000` 으로(또는 빈 값 `""`) |
| 실제 폰에서만 연결 실패 | `10.0.2.2` · `localhost` 는 폰에서 PC 가 아님 | 5장: PC IP + `--host 0.0.0.0` + 같은 와이파이 + 방화벽 허용 |
| `env.json` 을 고쳤는데 그대로 | 실행할 때 한 번 읽는 값이라 `r` 로는 안 바뀜 | `q` 로 끄고 `flutter run` 다시 |
| `No supported devices connected` | 에뮬레이터가 안 켜졌거나 아직 부팅 중 | `flutter devices` 로 확인, 1 ~ 2분 기다리기 |
| 에뮬레이터 창이 떴다가 사라짐 (`WHPX: Unexpected VP exit`) | 저장된 상태로 부팅하다 실패 | 4장 방법 C: `-no-snapshot -gpu swiftshader_indirect` |
| `Running multiple emulators with the same AVD` 오류 | 같은 에뮬레이터가 이미 켜져 있음(창이 안 보이거나 멈춤) | 작업 관리자에서 `qemu-system-x86_64` · `emulator` 를 끝내고 다시 켭니다 |
| 에뮬레이터 창은 있는데 `flutter devices` · `adb devices` 에 없음 | 에뮬레이터가 멈췄거나 adb 가 놓침 | `adb kill-server` → `adb start-server`, 그래도 없으면 에뮬레이터를 끄고 방법 C 로 다시 |
| 가상화(Hypervisor) 오류로 에뮬레이터가 안 켜짐 | BIOS 가상화 꺼짐 / Windows 하이퍼바이저 플랫폼 꺼짐 | 3-2 아래 안내대로 켜고 재부팅 |
| 첫 `flutter run` 이 `Gradle` 에서 오래 멈춤 | 처음에 필요한 파일을 받는 중 | 5분 정도 기다립니다. 회사 · 학교망에서 막히면 다른 네트워크 |
| `Android license status unknown` | 라이선스 동의 안 함 / Command-line Tools 없음 | 3-1 의 SDK Tools 체크 → `flutter doctor --android-licenses` |
| 에뮬레이터에 "Chrome isn't responding" | 에뮬레이터 속 크롬이 느림 | Wait, 또는 `adb shell am force-stop com.android.chrome` |
| 폴더가 한글 경로 | 빌드 도구가 경로를 못 읽음 | `C:\work\jeju-hanbakwi` 처럼 영문 경로로 옮깁니다 |

명령 하나하나의 뜻은 `flutter run -h`, `flutter emulators -h` 로 볼 수 있습니다.

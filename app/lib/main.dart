// 앱이 켜질 때 가장 먼저 실행되는 파일입니다. 화면을 그리기 전에 필요한 준비물을 만든 뒤 runApp 으로 앱을 시작합니다.
// 준비물은 로그인(AuthService) · 내 AI 키 보관소(AiKeyStore) · 서버 호출(ApiClient) 세 가지이고, 모두 JejuApp(app.dart)에 넘깁니다.
// Future 는 "끝날 때까지 기다려야 하는 일"이고, async 함수 안의 await 는 그 일이 끝날 때까지 기다린다는 표시입니다.
// Dart 의 ? 는 "null(값 없음)일 수도 있다", ! 는 "null 이 아니라고 내가 보장한다", ?? 는 "null 이면 대신 이 값", ?. 는 "null 이면 건너뜀"입니다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'auth/ai_key_store.dart';
import 'auth/auth_service.dart';

// 앱의 시작점. Dart 는 항상 main 함수부터 실행합니다.
Future<void> main() async {
  // runApp 전에 await 로 기다리는 일을 하려면 Flutter 엔진과의 연결을 먼저 준비해야 합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 0) 한글 글꼴을 먼저 다 불러온 뒤 화면을 그립니다.
  //    글꼴이 늦게 오면 첫 화면의 칩·버튼 너비가 잘못 계산되어 글자가 잘립니다(웹 실행에서 발생).
  await _loadFonts();

  // 1) 로그인 준비(Supabase 설정이 비어 있으면 건너뜁니다).
  final auth = await createAuthService();

  // 2) 설정 화면에 넣어 둔 내 AI 키를 기기 보안 저장소에서 꺼냅니다(없으면 그대로 진행).
  final aiKey = AiKeyStore(SecureKeyVault());
  await aiKey.load();

  // 3) API 클라이언트. 요청마다 로그인 토큰을, 일정 요청에는 내 AI 키를 꺼내 붙입니다.
  final api = ApiClient(tokenProvider: () => auth.accessToken, aiKeyProvider: () => aiKey.key);

  runApp(JejuApp(api: api, auth: auth, aiKey: aiKey));
}

// 글꼴 파일(assets/fonts)을 읽어 'Pretendard' 라는 이름으로 등록합니다. 파일 읽기는 기다려야 하는 일이라 Future 입니다.
Future<void> _loadFonts() async {
  final loader = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
  await loader.load();
}

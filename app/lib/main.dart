import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'auth/ai_key_store.dart';
import 'auth/auth_service.dart';

Future<void> main() async {
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

Future<void> _loadFonts() async {
  final loader = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
  await loader.load();
}

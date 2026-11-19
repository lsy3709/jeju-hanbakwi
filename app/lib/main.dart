import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 로그인 준비(Supabase 설정이 비어 있으면 건너뜁니다).
  final auth = await createAuthService();

  // 2) API 클라이언트. 요청마다 로그인 토큰을 꺼내 붙입니다.
  final api = ApiClient(tokenProvider: () => auth.accessToken);

  runApp(JejuApp(api: api, auth: auth));
}

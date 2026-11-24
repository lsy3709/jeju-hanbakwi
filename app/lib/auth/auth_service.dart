import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// 앱(안드로이드)이 로그인 뒤 돌아올 딥링크 주소.
/// AndroidManifest.xml 의 intent-filter, Supabase 의 Redirect URLs 와 글자까지 같아야 합니다.
const String appLoginCallback = 'com.goldmagnet.jejuhanbakwi://login-callback';

/// 로그인 뒤 돌아올 주소. 웹은 지금 열려 있는 주소의 origin(예: `https://내앱.vercel.app`), 앱은 딥링크.
/// 웹에서 비워 두면 Supabase 가 Site URL(Next.js 웹)로 보내 버리므로 꼭 넘깁니다.
/// 이 주소도 Supabase 의 Redirect URLs 에 있어야 합니다.
String loginRedirectUrl({required bool isWeb, required Uri base}) =>
    isWeb ? base.origin : appLoginCallback;

/// 로그인 상태를 들고 있는 곳. Supabase 는 "로그인"에만 씁니다.
/// (데이터 조회·저장은 전부 API 서버를 거칩니다.)
class AuthService extends ChangeNotifier {
  /// [configured] 가 false 면 Supabase 를 건드리지 않습니다(수업 초반, 설정 값이 비어 있을 때).
  AuthService({required this.configured});

  /// 설정 값이 없는 상태(테스트나 수업 초반)용.
  AuthService.disabled() : configured = false;

  final bool configured;
  Session? _session;
  StreamSubscription<AuthState>? _subscription;

  bool get loggedIn => _session != null;

  /// API 요청의 `Authorization: Bearer` 에 넣을 토큰.
  String? get accessToken => _session?.accessToken;

  String? get email => _session?.user.email;

  /// Supabase.initialize 가 끝난 뒤에 불러 주세요.
  void start() {
    if (!configured) return;
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    // 로그인·로그아웃·토큰 갱신이 일어날 때마다 세션이 바뀝니다.
    _subscription = auth.onAuthStateChange.listen(
      (data) {
        _session = data.session;
        notifyListeners();
      },
      // 오프라인이면 토큰 갱신 실패가 이 스트림으로 옵니다. 받지 않으면 처리되지 않은 오류로 남는데,
      // 다음 갱신 때 다시 시도되므로 여기서는 넘깁니다.
      onError: (_) {},
    );
  }

  /// 구글 로그인. 웹은 지금 열려 있는 주소로, 앱은 딥링크로 돌아옵니다([loginRedirectUrl]).
  Future<void> signInWithGoogle() async {
    if (!configured) return;
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: loginRedirectUrl(isWeb: kIsWeb, base: Uri.base),
    );
  }

  Future<void> signOut() async {
    if (!configured) return;
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// main.dart 에서 한 번 부르는 준비 함수.
Future<AuthService> createAuthService() async {
  if (Config.hasSupabase) {
    // 패키지 최신 버전은 anonKey 대신 publishableKey 라는 이름을 씁니다(같은 공개 키 자리).
    await Supabase.initialize(url: Config.supabaseUrl, publishableKey: Config.supabaseAnonKey);
  }
  return AuthService(configured: Config.hasSupabase)..start();
}

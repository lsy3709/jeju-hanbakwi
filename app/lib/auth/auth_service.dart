// 구글 로그인과 "지금 로그인했는가"를 들고 있는 파일입니다. Supabase(로그인 서비스)는 여기서만 부르고, 데이터는 전부 서버를 거칩니다.
// 화면은 AppScope 로 이 객체를 받아 loggedIn · email 을 읽고, ApiClient 는 accessToken 을 요청 헤더에 싣습니다.
// 세션(Session)은 "로그인된 상태"를 나타내는 정보이고, 그 안의 accessToken 이 서버에 보여 주는 증표입니다.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// 앱(안드로이드)이 로그인 뒤 돌아올 딥링크 주소.
/// AndroidManifest.xml 의 intent-filter, Supabase 의 Redirect URLs 와 글자까지 같아야 합니다.
// const 는 값이 절대 바뀌지 않는 상수라는 뜻입니다. 같은 글자를 여러 곳에 쓰다 틀리지 않도록 한곳에 둡니다.
const String appLoginCallback = 'com.goldmagnet.jejuhanbakwi://login-callback';

/// 로그인 뒤 돌아올 주소. 웹은 지금 열려 있는 주소의 origin(예: `https://내앱.vercel.app`), 앱은 딥링크.
/// 웹에서 비워 두면 Supabase 가 Site URL(Next.js 웹)로 보내 버리므로 꼭 넘깁니다.
/// 이 주소도 Supabase 의 Redirect URLs 에 있어야 합니다.
// origin 은 주소에서 "https://이름:포트" 까지만 뗀 것입니다(#/planner 같은 뒷부분은 버림).
// 화면 없이 계산만 하는 함수라 테스트(test/auth_redirect_test.dart)로 바로 확인할 수 있습니다.
String loginRedirectUrl({required bool isWeb, required Uri base}) =>
    isWeb ? base.origin : appLoginCallback;

/// 로그인 상태를 들고 있는 곳. Supabase 는 "로그인"에만 씁니다.
/// (데이터 조회·저장은 전부 API 서버를 거칩니다.)
class AuthService extends ChangeNotifier {
  /// [configured] 가 false 면 Supabase 를 건드리지 않습니다(수업 초반, 설정 값이 비어 있을 때).
  // required 는 이름 붙은 값을 꼭 넘겨야 한다는 뜻입니다. configured 가 false 면 Supabase 설정이 비어 있다는 뜻이라 아래 함수들이 아무 일도 하지 않습니다.
  AuthService({required this.configured});

  /// 설정 값이 없는 상태(테스트나 수업 초반)용.
  AuthService.disabled() : configured = false;

  final bool configured;
  Session? _session;
  // Stream 은 시간에 걸쳐 여러 번 오는 소식입니다. 구독(subscription)은 그 소식을 듣고 있는 상태이며, dispose 에서 끊어야 합니다.
  StreamSubscription<AuthState>? _subscription;

  // 세션이 있으면(null 이 아니면) 로그인한 것입니다. _session?.accessToken 의 ?. 는 세션이 null 이면 null 을 돌려줍니다.
  bool get loggedIn => _session != null;

  /// API 요청의 `Authorization: Bearer` 에 넣을 토큰.
  String? get accessToken => _session?.accessToken;

  String? get email => _session?.user.email;

  /// Supabase.initialize 가 끝난 뒤에 불러 주세요.
  void start() {
    if (!configured) return;
    // 처음 켤 때 이미 로그인된 세션이 남아 있을 수 있어 현재 값을 먼저 읽고, 이후 바뀔 때마다 아래 listen 이 알려 줍니다.
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
  // redirectTo: 로그인을 마친 뒤 돌아올 곳입니다. kIsWeb 은 "지금 웹(크롬)에서 돌고 있는가", Uri.base 는 "지금 열려 있는 주소"입니다.
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
  // 듣기를 끊지 않으면 이 객체가 사라진 뒤에도 소식이 계속 와서 메모리가 샙니다.
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ..start() 는 "방금 만든 객체에 start() 를 부르고, 그 객체를 돌려준다"는 문법(캐스케이드)입니다.
/// main.dart 에서 한 번 부르는 준비 함수.
Future<AuthService> createAuthService() async {
  if (Config.hasSupabase) {
    // 패키지 최신 버전은 anonKey 대신 publishableKey 라는 이름을 씁니다(같은 공개 키 자리).
    await Supabase.initialize(url: Config.supabaseUrl, publishableKey: Config.supabaseAnonKey);
  }
  return AuthService(configured: Config.hasSupabase)..start();
}

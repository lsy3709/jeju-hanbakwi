// 구글 로그인과 "지금 로그인했는가"를 들고 있는 파일입니다. Supabase(로그인 서비스)는 여기서만 부르고, 데이터는 전부 서버를 거칩니다.
// 화면은 AppScope 로 이 객체를 받아 loggedIn · email 을 읽고, ApiClient 는 accessToken 을 요청 헤더에 싣습니다.
// 세션(Session)은 "로그인된 상태"를 나타내는 정보이고, 그 안의 accessToken 이 서버에 보여 주는 증표입니다.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

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

  /// 구글 로그인. 웹은 현재 주소로 돌아오고, 앱은 딥링크 스킴으로 돌아옵니다.
  /// (안드로이드 AndroidManifest.xml 의 intent-filter 와 같은 스킴)
  // redirectTo: 로그인을 마친 뒤 돌아올 곳입니다. 웹(kIsWeb)은 null 로 두면 현재 주소로 돌아오고, 앱은 AndroidManifest 에 등록한 약속된 주소(딥링크)로 돌아옵니다.
  Future<void> signInWithGoogle() async {
    if (!configured) return;
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.goldmagnet.jejuhanbakwi://login-callback',
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

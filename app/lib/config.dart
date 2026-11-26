import 'package:flutter/foundation.dart' show kIsWeb;

/// 실행할 때 `--dart-define-from-file=env.json` 으로 넣는 설정 값을 한곳에서 읽습니다.
/// 값이 없으면 빈 문자열(또는 기본값)이 됩니다.
class Config {
  static const String _apiUrl = String.fromEnvironment('API_URL');

  /// API 서버 주소. 고르는 규칙은 아래 [resolveApiUrl] 에 있습니다.
  static String get apiUrl => resolveApiUrl(_apiUrl, isWeb: kIsWeb);

  static const String _webUrl = String.fromEnvironment('WEB_URL');

  /// 웹(Next.js) 주소. 3D 지도처럼 웹에서 만든 화면을 앱에 끼워 넣을 때 씁니다. 규칙은 [resolveWebUrl].
  static String get webUrl => resolveWebUrl(_webUrl, isWeb: kIsWeb);

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// 로그인 설정이 채워져 있는지. false 면 로그인 버튼 대신 안내를 보여 줍니다.
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// 에뮬레이터 안에서 "내 PC" 를 가리키는 특별한 주소. 에뮬레이터 밖(크롬 등)에서는 닿지 않습니다.
const String emulatorHost = '10.0.2.2';

/// `env.json` 의 `API_URL` 과 실행 환경으로 실제로 부를 서버 주소를 고릅니다.
///
/// - 비어 있으면: 크롬(웹)은 `http://localhost:8000`, 에뮬레이터는 `http://10.0.2.2:8000`
/// - 크롬인데 `10.0.2.2` 가 적혀 있으면: `localhost` 로 바꿉니다.
///   (에뮬레이터용으로 적어 둔 env.json 으로 크롬을 켜도 연결되게 하려는 것)
/// - 그 밖의 주소(배포 주소, 실제 폰용 PC IP 등)는 적힌 그대로 씁니다.
String resolveApiUrl(String defined, {required bool isWeb}) => _resolveLocalUrl(defined, isWeb: isWeb, port: 8000);

/// `env.json` 의 `WEB_URL` 로 웹 주소를 고릅니다. 규칙은 [resolveApiUrl] 과 같고, 기본 포트만 3000 입니다.
String resolveWebUrl(String defined, {required bool isWeb}) => _resolveLocalUrl(defined, isWeb: isWeb, port: 3000);

String _resolveLocalUrl(String defined, {required bool isWeb, required int port}) {
  var url = defined.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (url.isEmpty) {
    return isWeb ? 'http://localhost:$port' : 'http://$emulatorHost:$port';
  }
  if (isWeb) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host == emulatorHost) {
      return uri.replace(host: 'localhost').toString();
    }
  }
  return url;
}

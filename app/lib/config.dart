import 'package:flutter/foundation.dart' show kIsWeb;

/// 실행할 때 `--dart-define-from-file=env.json` 으로 넣는 설정 값을 한곳에서 읽습니다.
/// 값이 없으면 빈 문자열(또는 기본값)이 됩니다.
class Config {
  static const String _apiUrl = String.fromEnvironment('API_URL');

  /// API 서버 주소. 고르는 규칙은 아래 [resolveApiUrl] 에 있습니다.
  static String get apiUrl => resolveApiUrl(_apiUrl, isWeb: kIsWeb);
}

/// 에뮬레이터 안에서 "내 PC" 를 가리키는 특별한 주소. 에뮬레이터 밖(크롬 등)에서는 닿지 않습니다.
const String emulatorHost = '10.0.2.2';

/// `env.json` 의 `API_URL` 과 실행 환경으로 실제로 부를 서버 주소를 고릅니다.
///
/// - 비어 있으면: 크롬(웹)은 `http://localhost:8000`, 에뮬레이터는 `http://10.0.2.2:8000`
/// - 크롬인데 `10.0.2.2` 가 적혀 있으면: `localhost` 로 바꿉니다.
///   (에뮬레이터용으로 적어 둔 env.json 으로 크롬을 켜도 연결되게 하려는 것)
/// - 그 밖의 주소(배포 주소, 실제 폰용 PC IP 등)는 적힌 그대로 씁니다.
String resolveApiUrl(String defined, {required bool isWeb}) {
  var url = defined.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (url.isEmpty) {
    return isWeb ? 'http://localhost:8000' : 'http://$emulatorHost:8000';
  }
  if (isWeb) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host == emulatorHost) {
      return uri.replace(host: 'localhost').toString();
    }
  }
  return url;
}

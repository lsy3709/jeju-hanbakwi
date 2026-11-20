import 'package:flutter/foundation.dart' show kIsWeb;

/// 실행할 때 `--dart-define-from-file=env.json` 으로 넣는 설정 값을 한곳에서 읽습니다.
/// 값이 없으면 빈 문자열(또는 기본값)이 됩니다.
class Config {
  static const String _apiUrl = String.fromEnvironment('API_URL');

  /// API 서버 주소. 비어 있으면 실행 환경에 맞는 기본값을 씁니다.
  /// - 안드로이드 에뮬레이터: PC 의 localhost 는 10.0.2.2
  /// - 웹: 그냥 localhost
  static String get apiUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    return kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
  }
}

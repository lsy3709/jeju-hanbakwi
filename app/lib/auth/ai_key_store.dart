import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 키 하나를 두는 곳. 진짜는 기기 보안 저장소([SecureKeyVault]), 테스트에서는 가짜를 넣습니다.
abstract class KeyVault {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

/// 기기 보안 저장소(안드로이드 Keystore · iOS Keychain)에 키를 둡니다.
class SecureKeyVault implements KeyVault {
  static const _name = 'jeju_hanbakwi_ai_key';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _name);

  @override
  Future<void> write(String key) => _storage.write(key: _name, value: key);

  @override
  Future<void> delete() => _storage.delete(key: _name);
}

/// 저장소 없이 메모리에만 두는 곳(테스트 · 저장소를 준비하지 않은 실행용).
class MemoryKeyVault implements KeyVault {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String key) async => _value = key;

  @override
  Future<void> delete() async => _value = null;
}

/// 사용자가 설정 화면에 넣은 자기 AI(Gemini) 키.
/// 키는 이 기기에만 두고, 일정 요청 때 X-Gemini-Key 헤더로 서버에 보냅니다(ApiClient 의 aiKeyProvider).
/// 서버는 그 요청에만 쓰고 저장하지 않습니다(docs/api.md).
class AiKeyStore extends ChangeNotifier {
  AiKeyStore(this._vault);
  final KeyVault _vault;

  String? _key;
  String? get key => _key;
  bool get hasKey => _key != null;

  /// 화면에 보여 줄 가린 키. 키 전체는 화면에 다시 그리지 않습니다.
  String? get masked => _key == null ? null : mask(_key!);

  /// 서버가 받는 모양과 같습니다: 영문 · 숫자 · _ · - · . 20~200자(마침표는 새 형식의 키에 들어 있습니다).
  static bool isKeyShape(String key) => RegExp(r'^[A-Za-z0-9_.\-]{20,200}$').hasMatch(key);

  static String mask(String key) =>
      key.length >= 12 ? '${key.substring(0, 4)}…${key.substring(key.length - 4)}' : '…';

  /// 앱을 켤 때 한 번. 저장소를 쓸 수 없어도 앱은 그대로 켜집니다(키 없음으로 봄).
  Future<void> load() async {
    try {
      final value = await _vault.read();
      _key = (value != null && isKeyShape(value)) ? value : null;
    } catch (_) {
      _key = null;
    }
    notifyListeners();
  }

  /// 저장합니다. 성공하면 null, 실패하면 화면에 보여 줄 까닭을 돌려줍니다.
  Future<String?> save(String raw) async {
    final key = raw.trim();
    if (key.isEmpty) return '키를 넣어 주세요.';
    if (!isKeyShape(key)) return '키 모양이 맞지 않아요. 공백 없이 통째로 붙여 넣었는지 확인해 주세요.';
    try {
      await _vault.write(key);
    } catch (_) {
      return '이 기기에 저장할 수 없어요. 잠시 뒤 다시 해 주세요.';
    }
    _key = key;
    notifyListeners();
    return null;
  }

  Future<void> clear() async {
    try {
      await _vault.delete();
    } catch (_) {
      // 저장소를 쓸 수 없으면 지울 것도 없습니다. 메모리의 키는 아래에서 지웁니다.
    }
    _key = null;
    notifyListeners();
  }
}

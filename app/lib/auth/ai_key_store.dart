// 사용자가 설정 화면에 넣은 "내 AI 키"를 기기에 보관하는 파일입니다. 설정 화면이 AiKeyStore 를 부르고, AiKeyStore 가 KeyVault(실제 보관 장소)를 부릅니다.
// 키는 비밀번호와 같은 비밀 값이라 일반 파일이 아니라 기기의 보안 저장소에 둡니다. 보관 장소를 KeyVault 라는 약속(abstract class)으로 감싼 이유는 테스트에서 가짜(MemoryKeyVault)를 끼우기 위해서입니다.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// abstract class 는 "이런 함수들을 갖춰야 한다"는 약속만 적은 클래스입니다. 아래 두 클래스가 각자 방식으로 채웁니다.
/// 키 하나를 두는 곳. 진짜는 기기 보안 저장소([SecureKeyVault]), 테스트에서는 가짜를 넣습니다.
abstract class KeyVault {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

// implements 는 위 약속(KeyVault)을 지키겠다는 선언이고, @override 는 약속된 함수를 실제로 만든다는 표시입니다.
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

// ChangeNotifier: 값이 바뀌면 notifyListeners() 로 알려서, 이 객체를 듣는 화면(설정 화면)이 다시 그려지게 합니다.
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
  // get 은 함수지만 변수처럼 store.masked 로 읽는 항목입니다. 키 일부만 보여 주는 이유는 화면에 비밀 값 전체를 드러내지 않으려는 것입니다.
  String? get masked => _key == null ? null : mask(_key!);

  /// 서버가 받는 모양과 같습니다: 영문 · 숫자 · _ · - · . 20~200자(마침표는 새 형식의 키에 들어 있습니다).
  static bool isKeyShape(String key) => RegExp(r'^[A-Za-z0-9_.\-]{20,200}$').hasMatch(key);

  static String mask(String key) =>
      key.length >= 12 ? '${key.substring(0, 4)}…${key.substring(key.length - 4)}' : '…';

  /// 앱을 켤 때 한 번. 저장소를 쓸 수 없어도 앱은 그대로 켜집니다(키 없음으로 봄).
  // try/catch: 저장소 읽기가 실패해도 앱이 멈추지 않도록 잡아서 "키 없음"으로 처리합니다. 오류를 삼키는 대신 앱이 계속 켜지는 쪽을 택한 것입니다.
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
  // 성공이면 null, 실패면 문구를 돌려줍니다. 화면은 돌려받은 글이 있으면 그대로 보여 주면 됩니다.
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

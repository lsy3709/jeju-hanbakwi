import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/auth/ai_key_store.dart';

const good = 'AIzaUserKey_1234567890-abcdefghij';

/// 기기 보안 저장소의 가짜. fail 이면 읽기·쓰기가 모두 오류를 냅니다(저장소를 쓸 수 없는 기기).
class FakeVault implements KeyVault {
  FakeVault([this.value]);
  String? value;
  bool fail = false;

  @override
  Future<String?> read() async => fail ? throw Exception('blocked') : value;

  @override
  Future<void> write(String key) async => fail ? throw Exception('blocked') : value = key;

  @override
  Future<void> delete() async => fail ? throw Exception('blocked') : value = null;
}

void main() {
  test('isKeyShape: 영문 · 숫자 · _ · - · . 20~200자만 통과', () {
    expect(AiKeyStore.isKeyShape(good), isTrue);
    expect(AiKeyStore.isKeyShape('AQ.fake-key-for-tests_0000000000.abcdef'), isTrue); // 마침표가 든 새 형식의 키
    expect(AiKeyStore.isKeyShape('short'), isFalse);
    expect(AiKeyStore.isKeyShape('has space in the key 1234567890'), isFalse);
    expect(AiKeyStore.isKeyShape('한글이들어간키1234567890abcdefgh'), isFalse);
    expect(AiKeyStore.isKeyShape('x' * 201), isFalse);
  });

  test('mask: 앞 4자와 뒤 4자만 보여 준다', () {
    expect(AiKeyStore.mask(good), 'AIza…ghij');
    expect(AiKeyStore.mask('abcd1234'), '…');
  });

  test('save: 앞뒤 공백을 떼고 저장하고, 듣는 쪽에 알린다', () async {
    final vault = FakeVault();
    final store = AiKeyStore(vault);
    var notified = 0;
    store.addListener(() => notified++);

    expect(await store.save('  $good\n'), isNull);
    expect(vault.value, good);
    expect(store.key, good);
    expect(store.hasKey, isTrue);
    expect(store.masked, 'AIza…ghij');
    expect(notified, 1);
  });

  test('save: 모양이 틀리거나 비어 있으면 저장하지 않고 까닭을 돌려준다', () async {
    final vault = FakeVault();
    final store = AiKeyStore(vault);
    expect(await store.save('틀린 키'), isNotNull);
    expect(await store.save('   '), isNotNull);
    expect(vault.value, isNull);
    expect(store.hasKey, isFalse);
  });

  test('load: 저장소에 있던 키를 되살리고, 모양이 틀린 값은 없는 것으로 본다', () async {
    final store = AiKeyStore(FakeVault(good));
    await store.load();
    expect(store.key, good);

    final broken = AiKeyStore(FakeVault('<script>'));
    await broken.load();
    expect(broken.key, isNull);
  });

  test('clear: 지우면 없어진다', () async {
    final vault = FakeVault(good);
    final store = AiKeyStore(vault);
    await store.load();
    await store.clear();
    expect(vault.value, isNull);
    expect(store.hasKey, isFalse);
  });

  test('저장소를 쓸 수 없는 기기에서도 앱이 죽지 않는다', () async {
    final vault = FakeVault()..fail = true;
    final store = AiKeyStore(vault);
    await store.load();
    expect(store.hasKey, isFalse);
    expect(await store.save(good), isNotNull);
    await store.clear();
  });
}

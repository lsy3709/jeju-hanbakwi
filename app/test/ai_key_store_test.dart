// 내 AI 키 보관소(AiKeyStore)의 단위 테스트입니다. 진짜 기기 보안 저장소 대신 FakeVault(가짜)를 끼워서, 저장 · 불러오기 · 지우기 · 저장소 고장 때의 동작을 확인합니다.

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/auth/ai_key_store.dart';

// 테스트용 가짜 키입니다. 실제 키가 아니고, 키 모양(영문 · 숫자 등 20자 이상)만 맞춘 글자입니다.
const good = 'AIzaUserKey_1234567890-abcdefghij';

// implements KeyVault: 진짜와 같은 함수들을 갖추되, fail 을 켜면 일부러 오류를 던져 "저장소를 쓸 수 없는 기기"를 흉내 냅니다.
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
  // 키 모양 검사와 가리기(mask) 확인: 짧은 값 · 공백 · 한글이 든 값은 거절하는지 봅니다.
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

  // 저장 · 불러오기 · 지우기: 값이 보관소에 들어가고, 듣는 쪽(addListener)에 알림이 가는지 확인합니다.
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

  // 저장소가 고장 나도 예외가 밖으로 새지 않고 "키 없음"으로 처리하는지 확인합니다.
  test('저장소를 쓸 수 없는 기기에서도 앱이 죽지 않는다', () async {
    final vault = FakeVault()..fail = true;
    final store = AiKeyStore(vault);
    await store.load();
    expect(store.hasKey, isFalse);
    expect(await store.save(good), isNotNull);
    await store.clear();
  });
}

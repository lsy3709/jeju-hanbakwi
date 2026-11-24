// 설정 화면(내 AI 키)의 화면 테스트입니다. FakeVault(가짜 보관소)와 KeyApi(키 확인 결과를 정하는 가짜 서버)로, 키 저장 · 가려 보이기 · 확인 · 지우기를 확인합니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/app.dart';
import 'package:jeju_hanbakwi/auth/ai_key_store.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';

import 'ai_key_store_test.dart' show FakeVault, good;
import 'support.dart';

// checkAiKey 만 다시 만들어서 서버가 "쓸 수 있는 키" 또는 "쓸 수 없는 키"라고 답하는 상황을 흉내 냅니다.
/// 키 확인 결과를 정해 줄 수 있는 가짜 서버.
class KeyApi extends PlanApi {
  bool keyOk = true;
  final checked = <String>[];

  @override
  Future<({bool ok, String message})> checkAiKey(String key) async {
    checked.add(key);
    return (ok: keyOk, message: keyOk ? '쓸 수 있는 키예요.' : '쓸 수 없는 키예요. 키를 다시 확인해 주세요.');
  }
}

// 도우미: 앱을 띄워 AI 플래너 탭의 설정(톱니바퀴)까지 들어가고, 가짜 보관소를 끼운 AiKeyStore 를 돌려줍니다.
Future<AiKeyStore> pumpSettings(WidgetTester tester, KeyApi api, FakeVault vault) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = AiKeyStore(vault);
  await store.load();
  await tester.pumpWidget(JejuApp(api: api, auth: AuthService.disabled(), aiKey: store));
  await tester.pumpAndSettle();
  await tester.tap(find.text('AI 플래너').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('설정'));
  await tester.pumpAndSettle();
  expect(find.text('내 AI 키'), findsOneWidget);
  return store;
}

void main() {
  // 저장하면 키는 가려서만 보이고(전체 글자는 화면에 없음), 확인 · 지우기가 되는지 확인합니다.
  testWidgets('설정: 키를 저장하면 가려서 보여 주고, 확인 · 지우기가 된다', (tester) async {
    final api = KeyApi();
    final vault = FakeVault();
    final store = await pumpSettings(tester, api, vault);

    await tester.enterText(find.byType(TextField), good);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(vault.value, good);
    expect(find.textContaining('AIza…ghij'), findsOneWidget);
    expect(find.textContaining(good), findsNothing); // 키 전체는 화면에 다시 그리지 않습니다

    await tester.tap(find.text('키 확인'));
    await tester.pumpAndSettle();
    expect(api.checked, [good]);
    expect(find.text('쓸 수 있는 키예요.'), findsOneWidget);

    await tester.tap(find.text('키 지우기'));
    await tester.pumpAndSettle();
    expect(vault.value, isNull);
    expect(store.hasKey, isFalse);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 틀린 키는 저장되지 않고 이유가 보이며, 서버가 쓸 수 없다고 답하면 그렇게 알려 주는지 확인합니다.
  testWidgets('설정: 모양이 틀린 키는 저장하지 않고 까닭을 보여 준다', (tester) async {
    final vault = FakeVault();
    await pumpSettings(tester, KeyApi(), vault);

    await tester.enterText(find.byType(TextField), '틀린 키');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(vault.value, isNull);
    expect(find.textContaining('키 모양이 맞지 않아요'), findsOneWidget);
  });

  testWidgets('설정: 틀린 키는 확인에서 그렇다고 알려 준다', (tester) async {
    final api = KeyApi()..keyOk = false;
    await pumpSettings(tester, api, FakeVault(good));

    await tester.tap(find.text('키 확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('쓸 수 없는 키예요'), findsOneWidget);
  });
}

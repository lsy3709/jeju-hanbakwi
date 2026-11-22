import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/widgets/title_dialog.dart';

/// 버튼 하나만 있는 화면. 누르면 제목 대화상자를 열고, 돌려받은 값을 [results] 에 담습니다.
Future<List<String?>> pumpOpener(WidgetTester tester) async {
  final results = <String?>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await askTripTitle(context, initial: '제주 여행')),
          child: const Text('열기'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  expect(find.text('일정 제목'), findsOneWidget);
  return results;
}

void main() {
  testWidgets('제목 대화상자: 바깥을 눌러 닫아도 오류 없이 null 을 돌려준다', (tester) async {
    final results = await pumpOpener(tester);

    await tester.tapAt(const Offset(5, 5)); // 대화상자 바깥
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('일정 제목'), findsNothing);
    expect(results, [null]);
  });

  testWidgets('제목 대화상자: 취소를 눌러도 오류 없이 null 을 돌려준다', (tester) async {
    final results = await pumpOpener(tester);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(results, [null]);
  });

  testWidgets('제목 대화상자: 저장을 누르면 적은 제목을 돌려주고, 비어 있으면 닫히지 않는다', (tester) async {
    final results = await pumpOpener(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('일정 제목'), findsOneWidget);

    await tester.enterText(find.byType(TextField), ' 부모님과 제주 ');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(results, ['부모님과 제주']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/app.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/controllers/planner_controller.dart';
import 'package:jeju_hanbakwi/models/itinerary.dart';

import 'support.dart';

void main() {
  test('PlanResult.fromJson: saved_trip 을 읽고, 없으면 null', () {
    final base = {'mode': 'ai', 'answer': 'a', 'itinerary': <Object>[], 'sources': <Object>[]};
    expect(PlanResult.fromJson(base).savedTrip, isNull);
    expect(PlanResult.fromJson({...base, 'saved_trip': null}).savedTrip, isNull);
    final saved = PlanResult.fromJson({
      ...base,
      'saved_trip': {'id': 12, 'title': '바다 보고 싶어요'},
    }).savedTrip;
    expect(saved?.id, 12);
    expect(saved?.title, '바다 보고 싶어요');
  });

  test('컨트롤러: 서버가 자동 저장해 준 일정은 처음부터 "저장됨"', () async {
    final api = PlanApi()..autoSaved = true;
    final c = PlannerController(api: api)..message = '바다 보고 싶어요';
    await c.submit();
    expect(c.saved, isTrue);
    expect(c.result?.savedTrip?.id, 7);

    // 자동 저장되지 않은 새 일정을 받으면 다시 "저장 안 됨"
    api.autoSaved = false;
    await c.submit();
    expect(c.saved, isFalse);
  });

  Future<void> pumpPlanner(WidgetTester tester, PlanApi api) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(JejuApp(api: api, auth: AuthService.disabled()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 플래너').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '바다 보고 싶어요');
    await tester.tap(find.text('일정 짜기'));
    await tester.pumpAndSettle();
  }

  testWidgets('화면: 자동 저장된 일정은 저장 단추 대신 안내를 보여 준다', (tester) async {
    await pumpPlanner(tester, PlanApi()..autoSaved = true);
    expect(find.textContaining('내 여행에 자동으로 저장했어요'), findsOneWidget);
    expect(find.text('내 여행에 저장'), findsNothing);
  });

  testWidgets('화면: 자동 저장되지 않은 일정은 지금까지처럼 저장 단추', (tester) async {
    await pumpPlanner(tester, PlanApi());
    expect(find.text('내 여행에 저장'), findsOneWidget);
    expect(find.textContaining('자동으로 저장했어요'), findsNothing);
  });
}

// 로그인한 채 AI 일정을 짜면 서버가 자동으로 "내 여행"에 저장해 주는 흐름의 테스트입니다. 응답의 saved_trip 읽기, 컨트롤러의 saved 값, 화면에 보이는 안내 문구를 차례로 확인합니다.
// testWidgets 는 실제 화면 위젯을 테스트용 화면에 띄우고 tester 로 누르고 글을 입력하는 테스트입니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/app.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/controllers/planner_controller.dart';
import 'package:jeju_hanbakwi/models/itinerary.dart';

import 'support.dart';

void main() {
  // 응답 읽기: saved_trip 이 없거나 null 이면 savedTrip 도 null 인지 확인합니다.
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

  // 컨트롤러 확인: 서버가 자동 저장해 준 일정이면 처음부터 saved 가 true 인지 확인합니다.
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

  // 도우미: 앱을 띄워 AI 플래너 탭에서 글을 입력하고 일정 짜기를 누릅니다. pumpAndSettle 은 화면 애니메이션이 끝날 때까지 기다립니다.
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

  // 화면 확인: 자동 저장이면 안내 문구, 아니면 저장 버튼이 보이는지 확인합니다.
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

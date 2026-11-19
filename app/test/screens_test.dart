import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/app.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/models/spot.dart';

import 'support.dart';

/// 좁은 폰 화면(하단 탭 레이아웃)으로 앱을 띄웁니다.
Future<void> pumpApp(WidgetTester tester, FakeApi api) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(JejuApp(api: api, auth: AuthService.disabled()));
  await tester.pumpAndSettle();
}

List<Spot> sampleSpots(int n) => [
      for (var i = 1; i <= n; i++) Spot.fromJson(spotJson(id: i, title: '관광지 $i', indoor: true)),
    ];

void main() {
  testWidgets('홈: 날씨 메시지와 추천 카드, 비 오는 날 실내 코스 버튼', (tester) async {
    final api = FakeApi(spots: sampleSpots(3), rainy: true);
    await pumpApp(tester, api);

    expect(find.text('어디로 한 바퀴 돌까요?'), findsOneWidget);
    expect(find.textContaining('비 소식'), findsOneWidget);
    expect(find.text('실내 코스 보기'), findsOneWidget);
    expect(find.text('관광지 1'), findsOneWidget);
    // 비 오는 날은 indoor=true 로 8개를 불러온다.
    // 탐색 탭도 미리 한 번 불러오므로, 홈이 보낸 요청(size 8)을 골라서 확인한다.
    final homeCall = api.spotCalls.firstWhere((c) => c['size'] == 8);
    expect(homeCall, containsPair('indoor', true));
  });

  testWidgets('홈: 테마 칩을 누르면 탐색 탭으로 가서 theme 로 검색', (tester) async {
    final api = FakeApi(spots: sampleSpots(2), rainy: false);
    await pumpApp(tester, api);

    await tester.tap(find.widgetWithText(ActionChip, '바다'));
    await tester.pumpAndSettle();

    expect(api.spotCalls.last, containsPair('theme', '바다'));
    expect(find.text('총 2곳'), findsOneWidget);
  });

  testWidgets('탐색: 결과가 20개를 넘으면 더 보기가 보이고 누르면 다음 쪽을 불러온다', (tester) async {
    final api = FakeApi(spots: sampleSpots(20), total: 45);
    await pumpApp(tester, api);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(find.text('총 45곳'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('더 보기'), 400, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();
    expect(api.spotCalls.last, containsPair('page', 2));
  });

  testWidgets('탐색: 결과가 없으면 안내 문구', (tester) async {
    final api = FakeApi(spots: const []);
    await pumpApp(tester, api);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(find.textContaining('조건에 맞는 곳이 없어요'), findsOneWidget);
  });

  testWidgets('탐색: 서버 오류면 안내 문구와 다시 시도 버튼, 누르면 다시 불러온다', (tester) async {
    final api = FakeApi(spots: sampleSpots(1), failSpots: true);
    await pumpApp(tester, api);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(find.textContaining('서버에 연결할 수 없어요'), findsWidgets);

    api.failSpots = false;
    await tester.tap(find.text('다시 시도').last);
    await tester.pumpAndSettle();
    expect(find.text('관광지 1'), findsOneWidget);
  });

  testWidgets('내 여행: Supabase 설정이 없으면 안내 문구(앱이 죽지 않음)', (tester) async {
    final api = FakeApi(spots: sampleSpots(1));
    await pumpApp(tester, api);

    await tester.tap(find.text('내 여행'));
    await tester.pumpAndSettle();
    expect(find.text('로그인 설정이 아직 없어요'), findsOneWidget);
  });

  testWidgets('넓은 화면(웹): 왼쪽 메뉴가 보이고 홈·탐색이 깨지지 않는다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi(spots: sampleSpots(6), rainy: false);
    await tester.pumpWidget(JejuApp(api: api, auth: AuthService.disabled()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(find.text('총 6곳'), findsOneWidget);
  });
}

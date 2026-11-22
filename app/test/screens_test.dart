import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/app.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/models/spot.dart';
import 'package:jeju_hanbakwi/screens/explore_screen.dart';

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

Finder exploreText(String text) => find.descendant(of: find.byType(ExploreScreen), matching: find.text(text));

void main() {
  testWidgets('탐색: 칩 A → 칩 B 를 누르고 B 응답이 먼저, A 응답이 나중에 와도 B 결과가 남는다', (tester) async {
    final api = GatedApi(total: 1);
    await pumpApp(tester, api);
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    api.gated = true;

    await tester.tap(exploreText('바다'));
    await tester.pump();
    await tester.tap(exploreText('오름'));
    await tester.pump();
    final a = api.pending.firstWhere((c) => c.theme == '바다');
    final b = api.pending.firstWhere((c) => c.theme == '오름');

    b.done.complete(pageOf(['B결과'], total: 1));
    await tester.pump();
    a.done.complete(pageOf(['A결과'], total: 1));
    await tester.pump();

    expect(find.text('B결과'), findsOneWidget);
    expect(find.text('A결과'), findsNothing);
  });

  testWidgets('탐색: "더 보기" 요청 중 칩을 바꾸면 옛 조건의 다음 묶음이 섞이지 않는다', (tester) async {
    final api = GatedApi(spots: sampleSpots(2), total: 40);
    await pumpApp(tester, api);
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    api.gated = true;

    await tester.tap(find.text('더 보기'));
    await tester.pump();
    final more = api.pending.firstWhere((c) => c.cursor == 2);

    await tester.tap(exploreText('바다'));
    await tester.pump();
    final fresh = api.pending.firstWhere((c) => c.theme == '바다');
    fresh.done.complete(pageOf(['바다첫묶음'], total: 40, nextCursor: 1));
    await tester.pump();
    more.done.complete(pageOf(['옛조건다음묶음'], total: null, nextCursor: 4, startId: 200));
    await tester.pump();

    expect(find.text('바다첫묶음'), findsOneWidget);
    expect(find.text('옛조건다음묶음'), findsNothing);
    // 버려진 "더 보기"가 로딩 상태를 남기지 않아 버튼이 다시 보인다.
    expect(find.text('더 보기'), findsOneWidget);
  });

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

  testWidgets('탐색: 결과가 20개를 넘으면 더 보기가 보이고 누르면 next_cursor 로 이어 불러온다', (tester) async {
    final api = FakeApi(spots: sampleSpots(20), total: 45);
    await pumpApp(tester, api);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(find.text('총 45곳'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('더 보기'), 400, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();
    expect(api.spotCalls.last, containsPair('cursor', 20));
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

  testWidgets('플래너: 글을 쓰고 "일정 짜기"를 누르면 결과가 보이고, 글이 비어 있으면 안내만', (tester) async {
    final api = PlanApi();
    await pumpApp(tester, api);
    await tester.tap(find.text('AI 플래너').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('일정 짜기'));
    await tester.pump();
    expect(find.text('하고 싶은 여행을 적어 주세요.'), findsOneWidget);
    expect(api.planCalls, isEmpty);

    await tester.enterText(find.byType(TextField), '바다 보고 싶어요');
    await tester.tap(find.text('3일'));
    await tester.tap(find.text('연인'));
    await tester.tap(find.text('일정 짜기'));
    await tester.pumpAndSettle();

    expect(api.planCalls.single, containsPair('message', '바다 보고 싶어요'));
    expect(api.planCalls.single, containsPair('days', 3));
    expect(api.planCalls.single, containsPair('companions', '연인'));
    expect(find.text('추천이에요'), findsOneWidget);
    expect(find.text('내 여행에 저장'), findsOneWidget);
  });
}

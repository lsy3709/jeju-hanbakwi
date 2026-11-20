import 'dart:async';

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

/// 응답 시점을 테스트가 정하는 API. gated 를 켜면 getSpots 가 Completer 가 풀릴 때까지 기다립니다.
class GatedApi extends FakeApi {
  GatedApi({super.spots, super.total});
  bool gated = false;
  final pending = <({String? theme, int page, Completer<SpotPage> done})>[];

  @override
  Future<SpotPage> getSpots({
    String? q,
    String? theme,
    String? area,
    String? category,
    bool? indoor,
    int page = 1,
    int size = 20,
  }) {
    if (!gated) {
      return super.getSpots(q: q, theme: theme, area: area, category: category, indoor: indoor, page: page, size: size);
    }
    final done = Completer<SpotPage>();
    pending.add((theme: theme, page: page, done: done));
    return done.future;
  }
}

SpotPage pageOf(List<String> titles, {int total = 2, int page = 1}) => SpotPage(
      items: [for (var i = 0; i < titles.length; i++) Spot.fromJson(spotJson(id: 100 + i + page * 10, title: titles[i]))],
      total: total,
      page: page,
      size: 20,
    );

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

  testWidgets('탐색: "더 보기" 요청 중 칩을 바꾸면 옛 조건의 2쪽이 섞이지 않는다', (tester) async {
    final api = GatedApi(spots: sampleSpots(2), total: 40);
    await pumpApp(tester, api);
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    api.gated = true;

    await tester.tap(find.text('더 보기'));
    await tester.pump();
    final more = api.pending.firstWhere((c) => c.page == 2);

    await tester.tap(exploreText('바다'));
    await tester.pump();
    final fresh = api.pending.firstWhere((c) => c.theme == '바다');
    fresh.done.complete(pageOf(['바다1쪽'], total: 40));
    await tester.pump();
    more.done.complete(pageOf(['옛조건2쪽'], total: 40, page: 2));
    await tester.pump();

    expect(find.text('바다1쪽'), findsOneWidget);
    expect(find.text('옛조건2쪽'), findsNothing);
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

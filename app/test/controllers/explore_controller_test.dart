import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/controllers/explore_controller.dart';
import 'package:jeju_hanbakwi/models/spot.dart';

import '../support.dart';

List<Spot> spots(int n) => [for (var i = 1; i <= n; i++) Spot.fromJson(spotJson(id: i, title: '관광지 $i'))];

void main() {
  test('start: 선택지(meta)와 1쪽을 불러온다', () async {
    final api = FakeApi(spots: spots(3));
    final c = ExploreController(api: api);
    expect(c.loading, true);

    await c.start();

    expect(c.meta?.themes, ['바다', '오름']);
    expect(c.items.length, 3);
    expect(c.total, 3);
    expect(c.loading, false);
    expect(c.error, isNull);
  });

  test('조건을 바꾸면 1쪽부터 다시 불러온다', () async {
    final api = FakeApi(spots: spots(2), total: 45);
    final c = ExploreController(api: api);
    await c.start();
    await c.loadMore();
    expect(api.spotCalls.last, containsPair('page', 2));
    expect(c.items.length, 4);

    await c.setTheme('바다');

    expect(api.spotCalls.last, containsPair('theme', '바다'));
    expect(api.spotCalls.last, containsPair('page', 1));
    expect(c.items.length, 2); // 2쪽 분량이 남지 않고 새 1쪽으로 교체
  });

  test('더 보기는 다음 쪽을 이어 붙인다', () async {
    final api = FakeApi(spots: spots(2), total: 45);
    final c = ExploreController(api: api);
    await c.start();

    await c.loadMore();

    expect(api.spotCalls.last, containsPair('page', 2));
    expect(c.items.length, 4);
    expect(c.hasMore, true);
  });

  test('검색어·지역·실내/실외 조건이 요청에 실린다', () async {
    final api = FakeApi(spots: spots(1));
    final c = ExploreController(api: api);
    await c.start();

    await c.search('돌담');
    await c.setArea('동부');
    await c.setIndoor(true);

    expect(api.spotCalls.last, containsPair('q', '돌담'));
    expect(api.spotCalls.last, containsPair('area', '동부'));
    expect(api.spotCalls.last, containsPair('indoor', true));
  });

  test('applyRequest: 홈이 보낸 조건으로 바꾸고 지역·분류는 비운다', () async {
    final api = FakeApi(spots: spots(1));
    final c = ExploreController(api: api);
    await c.start();
    await c.setArea('동부');

    await c.applyRequest(q: '바다', theme: '바다', indoor: false);

    expect(c.area, isNull);
    expect(c.query, '바다');
    expect(api.spotCalls.last, containsPair('theme', '바다'));
    expect(api.spotCalls.last, containsPair('indoor', false));
  });

  test('A 요청 뒤 B 요청에서 B 가 먼저, A 가 나중에 와도 B 결과가 남는다', () async {
    final api = GatedApi(total: 1);
    final c = ExploreController(api: api);
    await c.start();
    api.gated = true;

    final fa = c.setTheme('바다');
    final fb = c.setTheme('오름');
    final a = api.pending.firstWhere((p) => p.theme == '바다');
    final b = api.pending.firstWhere((p) => p.theme == '오름');

    b.done.complete(pageOf(['B결과'], total: 1));
    await fb;
    a.done.complete(pageOf(['A결과'], total: 1));
    await fa;

    expect(c.items.map((s) => s.title), ['B결과']);
    expect(c.loading, false);
  });

  test('더 보기 중에 조건을 바꾸면 옛 조건의 2쪽이 섞이지 않는다', () async {
    final api = GatedApi(spots: spots(2), total: 40);
    final c = ExploreController(api: api);
    await c.start();
    api.gated = true;

    final more = c.loadMore();
    expect(c.loadingMore, true);
    final oldPage2 = api.pending.firstWhere((p) => p.page == 2);

    final fresh = c.setTheme('바다');
    final newPage1 = api.pending.firstWhere((p) => p.theme == '바다');
    newPage1.done.complete(pageOf(['바다1쪽'], total: 40));
    await fresh;
    oldPage2.done.complete(pageOf(['옛조건2쪽'], total: 40, page: 2));
    await more;

    expect(c.items.map((s) => s.title), ['바다1쪽']);
    expect(c.loadingMore, false); // 버려진 "더 보기"가 로딩 표시를 남기지 않는다
  });

  test('불러오기에 실패하면 오류 문구를 갖고, 다시 불러오면 지워진다', () async {
    final api = FakeApi(spots: spots(1), failSpots: true);
    final c = ExploreController(api: api);
    await c.start();

    expect(c.error, contains('서버에 연결할 수 없어요'));
    expect(c.loading, false);

    api.failSpots = false;
    await c.reload();
    expect(c.error, isNull);
    expect(c.items.length, 1);
  });

  test('더 보기가 실패하면 목록은 그대로 두고 오류 문구를 돌려준다', () async {
    final api = FakeApi(spots: spots(2), total: 45);
    final c = ExploreController(api: api);
    await c.start();
    api.failSpots = true;

    final message = await c.loadMore();

    expect(message, contains('서버에 연결할 수 없어요'));
    expect(c.items.length, 2);
    expect(c.loadingMore, false);
    expect(c.error, isNull); // 목록 전체를 오류 화면으로 바꾸지 않는다
  });
}

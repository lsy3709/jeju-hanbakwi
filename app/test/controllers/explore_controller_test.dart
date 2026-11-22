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

  test('조건을 바꾸면 커서를 버리고 처음부터 다시 불러온다', () async {
    final api = FakeApi(spots: spots(2), total: 45);
    final c = ExploreController(api: api);
    await c.start();
    await c.loadMore();
    expect(api.spotCalls.last, containsPair('cursor', 2));
    expect(c.items.length, 4);

    await c.setTheme('바다');

    expect(api.spotCalls.last, containsPair('theme', '바다'));
    expect(api.spotCalls.last, containsPair('cursor', null));
    expect(c.items.length, 2); // 이어 받은 분량이 남지 않고 새 첫 묶음으로 교체
    expect(c.nextCursor, 2);
  });

  test('더 보기는 서버가 준 next_cursor 를 그대로 보내 다음 묶음을 이어 붙인다', () async {
    final api = FakeApi(spots: spots(2), total: 45);
    final c = ExploreController(api: api);
    await c.start();
    expect(api.spotCalls.last, containsPair('cursor', null));

    await c.loadMore();
    expect(api.spotCalls.last, containsPair('cursor', 2));
    await c.loadMore();
    expect(api.spotCalls.last, containsPair('cursor', 4));

    expect(c.items.length, 6);
    expect(c.hasMore, true);
  });

  test('이어 받은 묶음이 겹치지 않는다(묶음마다 다른 줄)', () async {
    final api = GatedApi(total: 4);
    final c = ExploreController(api: api);
    api.gated = true;
    final start = c.reload();
    api.pending.single.done.complete(pageOf(['1', '2'], total: 4, nextCursor: 2, startId: 1));
    await start;

    final more = c.loadMore();
    expect(api.pending.last.cursor, 2);
    api.pending.last.done.complete(pageOf(['3', '4'], total: null, nextCursor: null, startId: 3));
    await more;

    expect(c.items.map((s) => s.id), [1, 2, 3, 4]);
    expect(c.items.map((s) => s.id).toSet().length, 4);
  });

  test('next_cursor 가 null 이면 hasMore 는 false 이고 더 보기는 서버를 부르지 않는다', () async {
    final api = FakeApi(spots: spots(2)); // total 2 → 첫 묶음에서 끝
    final c = ExploreController(api: api);
    await c.start();

    expect(c.nextCursor, isNull);
    expect(c.hasMore, false);
    final callsBefore = api.spotCalls.length;
    expect(await c.loadMore(), isNull);
    expect(api.spotCalls.length, callsBefore);
  });

  test('이어지는 묶음의 total 이 null 이어도 첫 묶음의 total 을 기억한다', () async {
    final api = FakeApi(spots: spots(2), total: 45); // 첫 응답만 total 45, 이후는 null
    final c = ExploreController(api: api);
    await c.start();
    expect(c.total, 45);

    await c.loadMore();

    expect(c.total, 45);
    expect(c.items.length, 4);
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

  test('더 보기 중에 조건을 바꾸면 옛 조건의 다음 묶음이 섞이지 않는다', () async {
    final api = GatedApi(spots: spots(2), total: 40);
    final c = ExploreController(api: api);
    await c.start();
    api.gated = true;

    final more = c.loadMore();
    expect(c.loadingMore, true);
    final oldMore = api.pending.firstWhere((p) => p.cursor == 2);

    final fresh = c.setTheme('바다');
    final newFirst = api.pending.firstWhere((p) => p.theme == '바다');
    newFirst.done.complete(pageOf(['바다첫묶음'], total: 40, nextCursor: 1));
    await fresh;
    oldMore.done.complete(pageOf(['옛조건다음묶음'], total: null, nextCursor: 4, startId: 200));
    await more;

    expect(c.items.map((s) => s.title), ['바다첫묶음']);
    expect(c.nextCursor, 1); // 옛 응답의 커서가 새 목록에 섞이지 않는다
    expect(c.total, 40);
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

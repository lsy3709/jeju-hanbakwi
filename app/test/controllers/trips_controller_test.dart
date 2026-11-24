// TripsController 의 단위 테스트입니다. 저장한 일정 목록 불러오기 · 더 보기 · 삭제 · 정지 계정 · 실패 처리를 가짜 서버(TripsApi)로 확인합니다.

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/controllers/trips_controller.dart';
import 'package:jeju_hanbakwi/models/cursor_page.dart';
import 'package:jeju_hanbakwi/models/trip.dart';

import '../support.dart';

Trip trip(int id, String title) => Trip(id: id, title: title, itinerary: const [], createdAt: '');

// 커서 = 지금까지 준 개수인 가짜 서버입니다. 실제 서버처럼 묶음 단위로 돌려줍니다.
/// 저장한 일정 목록·삭제만 흉내 내는 가짜 서버. 커서 = 이미 준 개수.
class TripsApi extends FakeApi {
  TripsApi({int count = 2}) : trips = [for (var i = 1; i <= count; i++) trip(i, '$i번째 여행')];
  final List<Trip> trips;
  bool failGet = false;
  bool failDelete = false;
  final deleted = <int>[];
  final cursors = <int?>[];

  @override
  Future<CursorPage<Trip>> getTrips({int? cursor, int size = 20}) async {
    cursors.add(cursor);
    if (failGet) throw const ApiException('서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.');
    final start = cursor ?? 0;
    final end = (start + size).clamp(0, trips.length);
    return CursorPage(items: trips.sublist(start, end), nextCursor: end < trips.length ? end : null);
  }

  @override
  Future<void> deleteTrip(int id) async {
    if (failDelete) throw const ApiException('찾을 수 없어요.', statusCode: 404);
    deleted.add(id);
  }
}

class _SuspendedApi extends FakeApi {
  @override
  Future<CursorPage<Trip>> getTrips({int? cursor, int size = 20}) async =>
      throw const ApiException('이용이 정지된 계정입니다. 관리자에게 문의해 주세요.', statusCode: 403);
}

void main() {
  // 불러오기: 목록을 받고, 다시 load 하면 커서를 버리고 처음부터 받으며, 실패 · 정지(403) 때 오류 문구가 남는지 확인합니다.
  test('load: 저장한 일정 목록을 불러온다', () async {
    final c = TripsController(api: TripsApi());
    expect(c.loading, true);

    await c.load();

    expect(c.loading, false);
    expect(c.trips.map((t) => t.title), ['1번째 여행', '2번째 여행']);
    expect(c.error, isNull);
    expect(c.hasMore, false);
  });

  // 더 보기: next_cursor 로 이어 붙이고, 실패하면 목록과 커서를 그대로 두며, 삭제 뒤에도 커서가 어긋나지 않는지 확인합니다.
  test('loadMore: next_cursor 를 그대로 보내 이어 붙이고, 끝나면 hasMore 가 false', () async {
    final api = TripsApi(count: 45);
    final c = TripsController(api: api);
    await c.load();
    expect(c.trips.length, 20);
    expect(c.hasMore, true);

    expect(await c.loadMore(), isNull);
    expect(api.cursors, [null, 20]);
    expect(c.trips.length, 40);

    await c.loadMore();
    expect(c.trips.length, 45);
    expect(c.trips.map((t) => t.id).toSet().length, 45); // 겹치지 않음
    expect(c.hasMore, false);

    final before = api.cursors.length;
    await c.loadMore();
    expect(api.cursors.length, before); // 끝났으면 서버를 부르지 않는다
  });

  test('loadMore 실패: 오류 문구를 돌려주고 목록·커서는 그대로(다시 누를 수 있음)', () async {
    final api = TripsApi(count: 45);
    final c = TripsController(api: api);
    await c.load();
    api.failGet = true;

    final message = await c.loadMore();

    expect(message, contains('서버에 연결할 수 없어요'));
    expect(c.trips.length, 20);
    expect(c.hasMore, true);
    expect(c.loadingMore, false);
    expect(c.error, isNull);
  });

  test('삭제 뒤에도 커서는 그대로라 다음 묶음이 어긋나지 않는다', () async {
    final api = TripsApi(count: 45);
    final c = TripsController(api: api);
    await c.load();

    await c.delete(c.trips.first);
    expect(c.trips.length, 19);
    await c.loadMore();

    expect(api.cursors.last, 20);
    expect(c.trips.length, 19 + 20);
  });

  test('load 를 다시 하면 커서를 버리고 처음부터 불러온다', () async {
    final api = TripsApi(count: 45);
    final c = TripsController(api: api);
    await c.load();
    await c.loadMore();
    expect(c.trips.length, 40);

    await c.load();

    expect(api.cursors.last, isNull);
    expect(c.trips.length, 20);
    expect(c.hasMore, true);
  });

  test('이용 정지(403): 서버가 준 안내 문구가 error 로 남는다', () async {
    final api = _SuspendedApi();
    final c = TripsController(api: api);

    await c.load();

    expect(c.error, '이용이 정지된 계정입니다. 관리자에게 문의해 주세요.');
    expect(c.loading, false);
  });

  test('load 실패: 오류 문구, 다시 load 하면 지워진다', () async {
    final api = TripsApi()..failGet = true;
    final c = TripsController(api: api);

    await c.load();
    expect(c.error, contains('서버에 연결할 수 없어요'));

    api.failGet = false;
    await c.load();
    expect(c.error, isNull);
    expect(c.trips.length, 2);
  });

  // 삭제: 성공하면 서버에 요청하고 목록에서 빠지며, 실패하면 오류 문구를 돌려주고 목록은 그대로인지 확인합니다.
  test('delete 성공: 서버에 요청하고 목록에서 빠진다', () async {
    final api = TripsApi();
    final c = TripsController(api: api);
    await c.load();

    final error = await c.delete(c.trips.first);

    expect(error, isNull);
    expect(api.deleted, [1]);
    expect(c.trips.map((t) => t.id), [2]);
  });

  test('delete 실패: 오류 문구를 돌려주고 목록은 그대로', () async {
    final api = TripsApi()..failDelete = true;
    final c = TripsController(api: api);
    await c.load();

    final error = await c.delete(c.trips.first);

    expect(error, '찾을 수 없어요.');
    expect(c.trips.length, 2);
  });
}

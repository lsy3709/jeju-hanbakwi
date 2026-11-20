import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/controllers/trips_controller.dart';
import 'package:jeju_hanbakwi/models/trip.dart';

import '../support.dart';

Trip trip(int id, String title) => Trip(id: id, title: title, itinerary: const [], createdAt: '');

/// 저장한 일정 목록·삭제만 흉내 내는 가짜 서버.
class TripsApi extends FakeApi {
  final trips = [trip(1, '첫 여행'), trip(2, '둘째 여행')];
  bool failGet = false;
  bool failDelete = false;
  final deleted = <int>[];

  @override
  Future<List<Trip>> getTrips() async {
    if (failGet) throw const ApiException('서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.');
    return List.of(trips);
  }

  @override
  Future<void> deleteTrip(int id) async {
    if (failDelete) throw const ApiException('찾을 수 없어요.', statusCode: 404);
    deleted.add(id);
  }
}

void main() {
  test('load: 저장한 일정 목록을 불러온다', () async {
    final c = TripsController(api: TripsApi());
    expect(c.loading, true);

    await c.load();

    expect(c.loading, false);
    expect(c.trips.map((t) => t.title), ['첫 여행', '둘째 여행']);
    expect(c.error, isNull);
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

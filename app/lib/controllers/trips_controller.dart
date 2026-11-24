// "내 여행 > 저장한 일정" 탭(screens/my_trips/trips_tab.dart)의 상태를 맡는 컨트롤러입니다. 화면 → TripsController → ApiClient.getTrips / deleteTrip 순입니다.
// 목록을 20개씩 나눠 받고(커서), 이어 받는 동안 목록이 바뀌어도 어긋나지 않게 요청 순번(_requestId)으로 옛 응답을 버립니다.

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/trip.dart';
import 'safe_notifier.dart';

/// "내 여행 > 저장한 일정" 탭의 상태: 저장한 일정 목록 불러오기 · "더 보기" · 삭제.
class TripsController extends ChangeNotifier with SafeNotifier {
  TripsController({required this.api, this.pageSize = 20});

  final ApiClient api;
  final int pageSize;

  List<Trip> trips = [];
  int? nextCursor; // 서버가 준 값을 그대로 보관. null 이면 끝.
  bool loading = true;
  bool loadingMore = false;
  String? error;

  /// 요청 순번. load 가 다시 시작되면 늦게 오는 옛 응답(특히 "더 보기")을 버리는 데 씁니다.
  int _requestId = 0;

  bool get hasMore => nextCursor != null;

  /// 처음부터 다시 불러옵니다(커서를 버림).
  Future<void> load() async {
    final id = ++_requestId;
    loading = true;
    loadingMore = false;
    error = null;
    notifyListeners();
    try {
      final loaded = await api.getTrips(size: pageSize);
      if (isDisposed || id != _requestId) return;
      trips = loaded.items;
      nextCursor = loaded.nextCursor;
    } on ApiException catch (e) {
      if (isDisposed || id != _requestId) return;
      error = e.message; // 이용 정지(403)면 서버가 준 안내 문구가 그대로 들어옵니다.
    }
    loading = false;
    notifyListeners();
  }

  /// "더 보기": 다음 묶음을 이어 붙입니다. 실패하면 오류 문구를 돌려줍니다(목록은 그대로).
  Future<String?> loadMore() async {
    final cursor = nextCursor;
    if (cursor == null || loadingMore) return null;
    final id = _requestId;
    loadingMore = true;
    notifyListeners();
    try {
      final more = await api.getTrips(cursor: cursor, size: pageSize);
      if (isDisposed || id != _requestId) return null;
      // 혹시 겹치는 일정이 오면(삭제·재저장 사이) 같은 id 는 한 번만 넣습니다.
      // map(...).toSet() 은 목록에서 id 만 뽑아 중복 없는 모음으로 만듭니다. 이미 있는 일정은 다시 넣지 않습니다.
      final known = trips.map((t) => t.id).toSet();
      trips = [...trips, ...more.items.where((t) => !known.contains(t.id))];
      nextCursor = more.nextCursor;
      loadingMore = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (isDisposed || id != _requestId) return null;
      loadingMore = false;
      notifyListeners();
      return e.message;
    }
  }

  /// 일정 하나 삭제. 성공하면 null(목록에서도 빠짐), 실패하면 오류 문구를 돌려줍니다.
  /// 커서는 "마지막으로 받은 줄 번호"라서 중간 줄이 빠져도 이어 받기가 어긋나지 않습니다.
  // 서버에서 지운 뒤에야 화면 목록에서도 뺍니다. 서버 삭제가 실패하면 목록은 그대로 둡니다.
  Future<String?> delete(Trip trip) async {
    try {
      await api.deleteTrip(trip.id);
      trips = trips.where((t) => t.id != trip.id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/trip.dart';
import 'safe_notifier.dart';

/// "내 여행 > 저장한 일정" 탭의 상태: 저장한 일정 목록 불러오기 · 삭제.
class TripsController extends ChangeNotifier with SafeNotifier {
  TripsController({required this.api});

  final ApiClient api;

  List<Trip> trips = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await api.getTrips();
      if (isDisposed) return;
      trips = loaded;
    } on ApiException catch (e) {
      if (isDisposed) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// 일정 하나 삭제. 성공하면 null(목록에서도 빠짐), 실패하면 오류 문구를 돌려줍니다.
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

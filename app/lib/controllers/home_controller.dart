import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/spot.dart';
import '../models/weather.dart';
import 'safe_notifier.dart';

/// 홈 화면의 상태: 날씨 · 테마 선택지 · "지금 가기 좋은 곳" 추천 목록.
class HomeController extends ChangeNotifier with SafeNotifier {
  HomeController({required this.api});

  final ApiClient api;

  bool loading = true;
  String? error;
  Meta? meta;
  Weather? weather; // 날씨는 실패해도 홈 전체를 막지 않습니다(null 이면 안내만).
  List<Spot> spots = [];

  /// 날씨 → 선택지 → 추천 목록 순서로 불러옵니다.
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      Weather? loadedWeather;
      try {
        loadedWeather = await api.getWeather();
      } on ApiException {
        loadedWeather = null; // 날씨 서비스가 503 이어도 계속 진행
      }
      final loadedMeta = await api.getMeta();
      // 비 오는 날은 실내, 아니면 실외 관광지를 먼저 보여 줍니다.
      final page = await api.getSpots(indoor: loadedWeather?.rainyToday == true, size: 8);
      if (isDisposed) return;
      weather = loadedWeather;
      meta = loadedMeta;
      spots = page.items;
    } on ApiException catch (e) {
      if (isDisposed) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }
}

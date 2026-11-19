import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/spot.dart';
import 'auth_service.dart';

/// 내가 찜한 관광지. 상세 화면의 하트와 "내 여행 > 찜한 곳"이 같은 값을 보게 한곳에 둡니다.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore({required this.api, required this.auth}) {
    auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final ApiClient api;
  final AuthService auth;

  List<Spot> items = [];
  bool loading = false;
  String? error;

  bool isFavorite(int spotId) => items.any((s) => s.id == spotId);

  void _onAuthChanged() {
    if (auth.loggedIn) {
      refresh();
    } else {
      items = [];
      error = null;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await api.getFavorites();
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// 찜 추가/해제. 실패하면 ApiException 을 그대로 던집니다(화면이 안내 문구를 띄움).
  Future<void> toggle(Spot spot) async {
    if (isFavorite(spot.id)) {
      await api.removeFavorite(spot.id);
      items = items.where((s) => s.id != spot.id).toList();
    } else {
      await api.addFavorite(spot.id);
      items = [spot, ...items]; // 최근에 찜한 순
    }
    notifyListeners();
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

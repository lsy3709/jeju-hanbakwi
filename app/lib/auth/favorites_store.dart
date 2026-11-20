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
      final fetched = await api.getFavorites();
      // 기다리는 사이 로그아웃했다면(이미 목록을 비웠다면) 이전 사용자의 찜을 다시 채우지 않습니다.
      if (!auth.loggedIn) {
        loading = false;
        notifyListeners();
        return;
      }
      items = fetched;
    } on ApiException catch (e) {
      if (!auth.loggedIn) {
        loading = false;
        notifyListeners();
        return;
      }
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// 진행 중인 요청이 있는 관광지 id. 찜 버튼을 연달아 눌러도 요청이 겹치지 않게 합니다.
  final _busy = <int>{};

  /// 찜 추가/해제. 실패하면 ApiException 을 그대로 던집니다(화면이 안내 문구를 띄움).
  Future<void> toggle(Spot spot) async {
    // 같은 관광지의 요청이 아직 끝나지 않았으면 두 번째 누름은 무시합니다(안 그러면 같은 카드가 2장 생깁니다).
    if (!_busy.add(spot.id)) return;
    try {
      if (isFavorite(spot.id)) {
        await api.removeFavorite(spot.id);
        items = items.where((s) => s.id != spot.id).toList();
      } else {
        await api.addFavorite(spot.id);
        items = [spot, ...items.where((s) => s.id != spot.id)]; // 최근에 찜한 순, 중복 방지
      }
      notifyListeners();
    } finally {
      _busy.remove(spot.id);
    }
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

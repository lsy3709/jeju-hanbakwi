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
  int? nextCursor; // 서버가 준 값을 그대로 보관. null 이면 끝.
  bool loading = false;
  bool loadingMore = false;
  String? error;

  /// 요청 순번. 새로고침·로그아웃이 일어나면 올라가서, 늦게 오는 옛 응답(더 보기 포함)을 버립니다.
  int _requestId = 0;

  bool get hasMore => nextCursor != null;

  /// 받아 둔 목록에는 아직 없지만 서버에 물어 "찜한 곳"으로 확인된 id.
  /// (찜이 20개를 넘으면 뒤쪽 찜은 "더 보기"를 누르기 전까지 items 에 없습니다)
  final _confirmed = <int>{};

  bool isFavorite(int spotId) => _confirmed.contains(spotId) || items.any((s) => s.id == spotId);

  /// 상세 화면을 열 때 부릅니다. 받아 둔 목록에 없고 뒤에 묶음이 더 남았을 때만 서버에 한 번 묻습니다.
  Future<void> check(int spotId) async {
    if (!auth.loggedIn || !hasMore || isFavorite(spotId)) return;
    final id = _requestId;
    try {
      final favorite = await api.hasFavorite(spotId);
      if (id != _requestId || !auth.loggedIn || !favorite) return;
      _confirmed.add(spotId);
      notifyListeners();
    } on ApiException {
      // 못 물어봤으면 빈 하트로 둡니다. 눌러도 서버가 "이미 찜"을 오류로 치지 않습니다.
    }
  }

  void _onAuthChanged() {
    if (auth.loggedIn) {
      refresh();
    } else {
      _requestId++; // 진행 중이던 응답은 이전 사용자의 것이므로 버립니다.
      _confirmed.clear();
      items = [];
      nextCursor = null;
      error = null;
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  /// 처음부터 다시 불러옵니다(커서를 버림).
  Future<void> refresh() async {
    final id = ++_requestId;
    loading = true;
    loadingMore = false;
    error = null;
    notifyListeners();
    try {
      final fetched = await api.getFavorites();
      // 기다리는 사이 로그아웃했거나 더 새 요청이 시작됐다면 이 응답은 버립니다.
      // (로그아웃으로 목록을 이미 비웠다면 이전 사용자의 찜을 다시 채우지 않습니다.)
      if (id != _requestId) {
        if (!auth.loggedIn) {
          loading = false;
          notifyListeners();
        }
        return;
      }
      if (!auth.loggedIn) {
        loading = false;
        notifyListeners();
        return;
      }
      items = fetched.items;
      nextCursor = fetched.nextCursor;
    } on ApiException catch (e) {
      if (id != _requestId || !auth.loggedIn) {
        if (!auth.loggedIn) {
          loading = false;
          notifyListeners();
        }
        return;
      }
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
      final more = await api.getFavorites(cursor: cursor);
      if (id != _requestId || !auth.loggedIn) return null;
      final known = items.map((s) => s.id).toSet(); // 그사이 새로 찜한 곳과 겹치면 한 번만
      items = [...items, ...more.items.where((s) => !known.contains(s.id))];
      nextCursor = more.nextCursor;
      loadingMore = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (id != _requestId) return null;
      loadingMore = false;
      notifyListeners();
      return e.message;
    }
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
        _confirmed.remove(spot.id);
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

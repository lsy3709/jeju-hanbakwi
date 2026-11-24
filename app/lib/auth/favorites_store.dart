// "내가 찜한 관광지" 목록을 한곳에서 들고 있는 파일입니다. 상세 화면의 하트와 "내 여행 > 찜한 곳" 탭이 같은 객체를 보므로 어디서 눌러도 두 화면이 함께 바뀝니다.
// 화면 → FavoritesStore → ApiClient 순으로 부릅니다. 로그인 상태(AuthService)가 바뀌면 스스로 불러오거나 비웁니다.
// 커서(cursor)는 "여기까지 받았다"는 표시로, 목록을 20개씩 나눠 받을 때 다음 묶음의 시작점을 서버가 알려 줍니다. 아래에 자주 나오는 _requestId 는 늦게 도착한 옛 응답을 버리기 위한 순번표입니다.

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/spot.dart';
import 'auth_service.dart';

/// 내가 찜한 관광지. 상세 화면의 하트와 "내 여행 > 찜한 곳"이 같은 값을 보게 한곳에 둡니다.
class FavoritesStore extends ChangeNotifier {
  // 생성자 안에서 auth.addListener 로 "로그인 상태가 바뀌면 알려 달라"고 등록하고, 지금 상태로도 한 번 맞춰 봅니다.
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

  // Set(<int>{}) 은 중복 없는 모음이라 "이 id 가 있나"를 빨리 확인할 수 있습니다.
  /// 받아 둔 목록에는 아직 없지만 서버에 물어 "찜한 곳"으로 확인된 id.
  /// (찜이 20개를 넘으면 뒤쪽 찜은 "더 보기"를 누르기 전까지 items 에 없습니다)
  final _confirmed = <int>{};

  bool isFavorite(int spotId) => _confirmed.contains(spotId) || items.any((s) => s.id == spotId);

  /// 상세 화면을 열 때 부릅니다. 받아 둔 목록에 없고 뒤에 묶음이 더 남았을 때만 서버에 한 번 묻습니다.
  // await 로 기다리는 동안 사용자가 로그아웃하거나 새로고침할 수 있어서, 돌아온 뒤 _requestId 가 그대로인지 확인하고 달라졌으면 응답을 버립니다.
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

  // 로그아웃하면 이전 사용자의 찜이 화면에 남지 않도록 모두 비웁니다. _requestId++ 는 진행 중인 요청의 응답을 무효로 만드는 일입니다.
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
  // 상태(loading 등)를 바꿀 때마다 notifyListeners() 를 불러야 화면이 다시 그려집니다. on ApiException catch (e) 는 서버 오류만 잡아 e.message 를 화면용 글로 씁니다.
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
      // [...a, ...b] 는 두 목록을 이어 새 목록을 만드는 문법입니다. 그사이 새로 찜한 곳과 겹치면 한 번만 넣습니다.
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
  // 같은 곳의 찜 요청이 끝나기 전에 다시 누르면 같은 카드가 두 번 들어갈 수 있어, 진행 중인 id 를 기억해 두고 막습니다.
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
    // finally 는 성공하든 실패하든 반드시 실행됩니다. 오류가 나도 "진행 중" 표시가 남아 버튼이 영영 막히는 일을 막습니다.
    } finally {
      _busy.remove(spot.id);
    }
  }

  @override
  // dispose 에서 auth 의 listener 를 해제합니다. 안 하면 이 객체가 사라진 뒤에도 로그인 변화가 계속 이 객체를 부릅니다.
  void dispose() {
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

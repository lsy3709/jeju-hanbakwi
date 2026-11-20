import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/spot.dart';
import 'safe_notifier.dart';

/// 탐색 화면의 상태: 검색 조건 · 목록 · 쪽 번호 · 불러오는 중 · 오류.
/// 위젯을 쓰지 않으므로 화면 없이 단위 테스트할 수 있습니다.
class ExploreController extends ChangeNotifier with SafeNotifier {
  ExploreController({required this.api, this.pageSize = 20});

  final ApiClient api;
  final int pageSize;

  // ---- 검색 조건 ----
  String query = '';
  String? theme;
  String? area;
  String? category;
  bool? indoor; // null = 전체

  // ---- 결과 ----
  Meta? meta; // 테마·지역·분류 선택지. 못 받아도 검색은 됩니다.
  List<Spot> items = [];
  int total = 0;
  int page = 1;
  bool loading = true;
  bool loadingMore = false;
  String? error;

  /// 요청 순번. 새 검색이 시작될 때마다 올라가며, 늦게 도착한 옛 응답을 알아보는 데 씁니다.
  int _requestId = 0;

  bool get hasMore => items.length < total;

  /// 화면이 처음 열릴 때 한 번: 선택지와 첫 쪽을 함께 불러옵니다.
  Future<void> start() async {
    await Future.wait([_loadMeta(), reload()]);
  }

  Future<void> _loadMeta() async {
    try {
      final loaded = await api.getMeta();
      if (isDisposed) return;
      meta = loaded;
      notifyListeners();
    } on ApiException {
      // 선택지를 못 받아도 검색은 됩니다. 칩이 비어 보일 뿐입니다.
    }
  }

  // ---- 조건 바꾸기: 바꾸면 1쪽부터 다시 검색합니다 ----

  Future<void> search(String text) {
    query = text;
    return reload();
  }

  Future<void> setTheme(String? value) {
    theme = value;
    return reload();
  }

  Future<void> setArea(String? value) {
    area = value;
    return reload();
  }

  Future<void> setCategory(String? value) {
    category = value;
    return reload();
  }

  Future<void> setIndoor(bool? value) {
    indoor = value;
    return reload();
  }

  /// 홈에서 "이 조건으로 찾아 줘" 하고 보낸 요청. 지역·분류는 비우고 새로 검색합니다.
  Future<void> applyRequest({String? q, String? theme, bool? indoor}) {
    query = q ?? '';
    this.theme = theme;
    this.indoor = indoor;
    area = null;
    category = null;
    return reload();
  }

  /// 첫 쪽부터 다시 검색.
  Future<void> reload() async {
    // 새 검색이 시작되면 이전 요청(검색·"더 보기")의 응답은 모두 버립니다.
    final id = ++_requestId;
    loading = true;
    loadingMore = false; // 버려질 "더 보기"가 로딩 표시를 남기지 않게 되돌립니다.
    error = null;
    notifyListeners();
    try {
      final result = await _fetch(1);
      if (isDisposed || id != _requestId) return; // 그사이 더 새 검색이 시작됐다면 버립니다.
      items = result.items;
      total = result.total;
      page = 1;
    } on ApiException catch (e) {
      if (isDisposed || id != _requestId) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// "더 보기": 다음 쪽을 이어 붙입니다. 실패하면 오류 문구를 돌려줍니다(목록은 그대로).
  Future<String?> loadMore() async {
    // 시작 시점의 번호를 잡아 둡니다. 응답이 올 때 번호가 달라졌다면 다른 조건의 목록에
    // 섞이면 안 되므로 버립니다.
    final id = _requestId;
    loadingMore = true;
    notifyListeners();
    try {
      final result = await _fetch(page + 1);
      if (isDisposed || id != _requestId) return null;
      items = [...items, ...result.items];
      total = result.total;
      page = result.page;
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

  Future<SpotPage> _fetch(int pageNumber) {
    return api.getSpots(
      q: query,
      theme: theme,
      area: area,
      category: category,
      indoor: indoor,
      page: pageNumber,
      size: pageSize,
    );
  }
}

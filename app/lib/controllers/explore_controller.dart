import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/spot.dart';
import 'safe_notifier.dart';

/// 탐색 화면의 상태: 검색 조건 · 목록 · 다음 커서 · 불러오는 중 · 오류.
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
  int total = 0; // 첫 묶음에서만 서버가 알려 주므로, 이어 받을 때 지우지 않고 기억합니다.
  int? nextCursor; // 다음 묶음을 받을 때 서버에 그대로 돌려보낼 값. null 이면 끝.
  bool loading = true;
  bool loadingMore = false;
  String? error;

  /// 요청 순번. 새 검색이 시작될 때마다 올라가며, 늦게 도착한 옛 응답을 알아보는 데 씁니다.
  int _requestId = 0;

  // 개수를 세지 않고 서버가 준 커서로만 판단합니다(보는 사이 목록이 바뀌어도 어긋나지 않음).
  bool get hasMore => nextCursor != null;

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

  // ---- 조건 바꾸기: 바꾸면 커서를 버리고 처음부터 다시 검색합니다 ----

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
      final result = await _fetch(null); // 커서를 버리고 처음부터
      if (isDisposed || id != _requestId) return; // 그사이 더 새 검색이 시작됐다면 버립니다.
      items = result.items;
      total = result.total ?? result.items.length;
      nextCursor = result.nextCursor;
    } on ApiException catch (e) {
      if (isDisposed || id != _requestId) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// "더 보기": 다음 묶음을 이어 붙입니다. 실패하면 오류 문구를 돌려줍니다(목록은 그대로).
  Future<String?> loadMore() async {
    // 시작 시점의 번호를 잡아 둡니다. 응답이 올 때 번호가 달라졌다면 다른 조건의 목록에
    // 섞이면 안 되므로 버립니다.
    final cursor = nextCursor;
    if (cursor == null || loadingMore) return null; // 끝이거나 이미 받는 중이면 아무것도 안 함
    final id = _requestId;
    loadingMore = true;
    notifyListeners();
    try {
      final result = await _fetch(cursor);
      if (isDisposed || id != _requestId) return null;
      items = [...items, ...result.items];
      if (result.total != null) total = result.total!; // 이어지는 묶음의 null 은 무시
      nextCursor = result.nextCursor;
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

  Future<SpotPage> _fetch(int? cursor) {
    return api.getSpots(
      q: query,
      theme: theme,
      area: area,
      category: category,
      indoor: indoor,
      cursor: cursor,
      size: pageSize,
    );
  }
}

// 찜 보관소(FavoritesStore)의 테스트입니다. 가짜 로그인(FakeAuth)과 가짜 서버(FavApi, PagedFavApi)로, 연달아 누르기 · 로그아웃 중 늦게 오는 응답 · 더 보기 · 정지 계정을 확인합니다.
// await 로 기다리는 사이에 일어날 수 있는 일을 일부러 만드는 것이 핵심입니다.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/auth/favorites_store.dart';
import 'package:jeju_hanbakwi/models/cursor_page.dart';
import 'package:jeju_hanbakwi/models/spot.dart';

import 'support.dart';

// super.disabled() 로 진짜 Supabase 없이 만들고, loggedIn 만 바꿔 끼웁니다. setLoggedIn 이 알림을 보내 FavoritesStore 가 반응하게 합니다.
/// 로그인 상태를 테스트에서 마음대로 바꾸는 가짜.
class FakeAuth extends AuthService {
  FakeAuth({bool loggedIn = false})
      : _in = loggedIn,
        super.disabled();
  bool _in;

  @override
  bool get loggedIn => _in;

  void setLoggedIn(bool value) {
    _in = value;
    notifyListeners();
  }
}

// Completer 로 응답 시점을 테스트가 정합니다(complete() 를 부를 때까지 서버가 답하지 않는 것처럼).
/// 찜 요청의 응답 시점을 Completer 로 조절하는 가짜 API.
class FavApi extends FakeApi {
  final addCalls = <int>[];
  final addGate = Completer<void>();
  final favoritesGate = Completer<CursorPage<Spot>>();

  @override
  Future<void> addFavorite(int spotId) async {
    addCalls.add(spotId);
    await addGate.future;
  }

  @override
  Future<CursorPage<Spot>> getFavorites({int? cursor, int size = 20}) => favoritesGate.future;
}

// 커서 = 지금까지 준 개수인 가짜 서버입니다. 실제 서버처럼 20개씩 나눠 줍니다.
/// 찜 목록을 묶음으로 돌려주는 가짜 서버(커서 = 이미 준 개수).
class PagedFavApi extends FakeApi {
  PagedFavApi(this.all);
  final List<Spot> all;
  final cursors = <int?>[];
  bool fail = false;

  @override
  Future<CursorPage<Spot>> getFavorites({int? cursor, int size = 20}) async {
    cursors.add(cursor);
    if (fail) throw const ApiException('이용이 정지된 계정입니다. 관리자에게 문의해 주세요.', statusCode: 403);
    final start = cursor ?? 0;
    final end = (start + size).clamp(0, all.length);
    return CursorPage(items: all.sublist(start, end), nextCursor: end < all.length ? end : null);
  }

  @override
  Future<void> removeFavorite(int spotId) async {}

  final asked = <int>[];

  @override
  Future<bool> hasFavorite(int spotId) async {
    asked.add(spotId);
    return all.any((s) => s.id == spotId);
  }
}

void main() {
  final spot = Spot.fromJson(spotJson(id: 7, title: '한라산'));

  // 연달아 두 번 눌러도 요청은 한 번, 목록에는 한 개만 들어가는지 확인합니다.
  test('toggle: 기다리지 않고 두 번 눌러도 요청 1번, 목록에 1개', () async {
    final api = FavApi();
    final store = FavoritesStore(api: api, auth: FakeAuth());

    final first = store.toggle(spot);
    final second = store.toggle(spot); // 첫 요청이 끝나기 전의 두 번째 누름
    api.addGate.complete();
    await Future.wait([first, second]);

    expect(api.addCalls, [7]);
    expect(store.items.map((s) => s.id), [7]);
  });

  // 응답을 기다리는 사이 로그아웃했을 때, 이전 사용자의 찜이 화면에 되살아나지 않는지 확인합니다.
  test('refresh: 기다리는 사이 로그아웃하면 이전 사용자의 찜을 다시 채우지 않는다', () async {
    final api = FavApi();
    final auth = FakeAuth(loggedIn: true);
    final store = FavoritesStore(api: api, auth: auth); // 생성 즉시 refresh 시작

    auth.setLoggedIn(false); // 응답이 오기 전에 로그아웃
    api.favoritesGate.complete(CursorPage(items: [spot], nextCursor: null));
    await Future<void>.delayed(Duration.zero);

    expect(store.items, isEmpty);
    expect(store.loading, false);
  });

  List<Spot> manySpots(int n) => [for (var i = 1; i <= n; i++) Spot.fromJson(spotJson(id: i, title: '찜 $i'))];

  // 로그인 상태로 만들면 생성자가 첫 묶음을 불러오므로, 그것이 끝나기를 기다립니다.
  Future<FavoritesStore> loggedInStore(ApiClient api) async {
    final store = FavoritesStore(api: api, auth: FakeAuth(loggedIn: true));
    await pumpEventQueue();
    return store;
  }

  // 더 보기(커서) 이어 붙이기, 뒤쪽 찜을 서버에 물어 보기(check), 찜 해제 뒤에도 커서가 어긋나지 않는지, 정지 계정의 문구를 확인합니다.
  test('더 보기: next_cursor 를 그대로 보내 다음 묶음을 이어 붙이고, 끝나면 hasMore 가 false', () async {
    final api = PagedFavApi(manySpots(45));
    final store = await loggedInStore(api);
    expect(store.items.length, 20);
    expect(store.hasMore, true);

    expect(await store.loadMore(), isNull);
    expect(api.cursors, [null, 20]);
    expect(store.items.length, 40);
    expect(store.items.map((s) => s.id).toSet().length, 40); // 겹치지 않음

    await store.loadMore();
    expect(api.cursors, [null, 20, 40]);
    expect(store.items.length, 45);
    expect(store.hasMore, false);

    final before = api.cursors.length;
    await store.loadMore(); // 끝났으면 서버를 부르지 않는다
    expect(api.cursors.length, before);
  });

  test('check: 아직 받지 않은 뒤쪽 찜도 서버에 물어 하트를 맞게 보여 준다', () async {
    final api = PagedFavApi(manySpots(45));
    final store = await loggedInStore(api);
    final last = api.all.last; // 45번째 — 첫 묶음(20개)에 없음
    expect(store.isFavorite(last.id), false);

    await store.check(last.id);
    expect(store.isFavorite(last.id), true);
    expect(api.asked, [last.id]);

    await store.check(store.items.first.id); // 이미 아는 곳은 묻지 않는다
    await store.check(last.id);
    expect(api.asked, [last.id]);

    await store.check(99999); // 찜하지 않은 곳
    expect(store.isFavorite(99999), false);

    await store.toggle(last); // 해제하면 빈 하트로
    expect(store.isFavorite(last.id), false);
  });

  test('check: 목록을 끝까지 받았으면 서버에 묻지 않는다', () async {
    final api = PagedFavApi(manySpots(5));
    final store = await loggedInStore(api);
    await store.check(99999);
    expect(api.asked, isEmpty);
  });

  test('찜 해제 뒤에도 커서는 그대로라 이어 받기가 어긋나지 않는다', () async {
    final api = PagedFavApi(manySpots(45));
    final store = await loggedInStore(api);

    await store.toggle(store.items.first); // 해제
    expect(store.items.length, 19);
    await store.loadMore();

    expect(api.cursors.last, 20);
    expect(store.items.length, 19 + 20);
  });

  test('이용 정지(403): 서버 문구가 error 로 남는다', () async {
    final api = PagedFavApi(const [])..fail = true;
    final store = await loggedInStore(api);

    expect(store.error, '이용이 정지된 계정입니다. 관리자에게 문의해 주세요.');
    expect(store.loading, false);
  });
}

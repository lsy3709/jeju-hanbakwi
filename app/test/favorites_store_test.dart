import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/auth/favorites_store.dart';
import 'package:jeju_hanbakwi/models/spot.dart';

import 'support.dart';

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

/// 찜 요청의 응답 시점을 Completer 로 조절하는 가짜 API.
class FavApi extends FakeApi {
  final addCalls = <int>[];
  final addGate = Completer<void>();
  final favoritesGate = Completer<List<Spot>>();

  @override
  Future<void> addFavorite(int spotId) async {
    addCalls.add(spotId);
    await addGate.future;
  }

  @override
  Future<List<Spot>> getFavorites() => favoritesGate.future;
}

void main() {
  final spot = Spot.fromJson(spotJson(id: 7, title: '한라산'));

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

  test('refresh: 기다리는 사이 로그아웃하면 이전 사용자의 찜을 다시 채우지 않는다', () async {
    final api = FavApi();
    final auth = FakeAuth(loggedIn: true);
    final store = FavoritesStore(api: api, auth: auth); // 생성 즉시 refresh 시작

    auth.setLoggedIn(false); // 응답이 오기 전에 로그아웃
    api.favoritesGate.complete([spot]);
    await Future<void>.delayed(Duration.zero);

    expect(store.items, isEmpty);
    expect(store.loading, false);
  });
}

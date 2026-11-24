// 화면 어디서든 api · 로그인 · 찜 · 탭 이동을 꺼내 쓰게 해 주는 통로(AppScope)와, 탭 사이 전달을 맡는 ShellController 가 있는 파일입니다.
// 화면들은 AppScope.of(context) 로 꺼내 쓰고, 이 객체들은 app.dart 에서 한 번만 만들어 넣습니다.
// ChangeNotifier 는 "값이 바뀌었다"고 notifyListeners() 로 알리면 그것을 듣는 화면이 다시 그려지게 하는 Flutter 기본 도구입니다.

import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'auth/ai_key_store.dart';
import 'auth/auth_service.dart';
import 'auth/favorites_store.dart';

// 홈 화면의 칩이나 검색창에서 탐색 탭으로 조건을 넘길 때 쓰는 값입니다. 각 조건은 ? 가 붙어 "없을 수도" 있습니다.
/// 탐색 탭에 "이 조건으로 검색해 줘" 하고 전달하는 요청.
/// 같은 조건을 두 번 보내도 새 요청으로 보이도록 객체 자체를 비교합니다.
class ExploreRequest {
  final String? q;
  final String? theme;
  final bool? indoor;
  const ExploreRequest({this.q, this.theme, this.indoor});
}

// 탭 번호(tab)가 바뀌면 notifyListeners() 로 알리고, 그것을 듣는 HomeShell 이 다시 그려져 탭이 바뀝니다.
/// 탭 이동과 탭 사이 전달을 맡는 작은 컨트롤러.
class ShellController extends ChangeNotifier {
  int tab = 0;
  ExploreRequest? exploreRequest;
  String? plannerPrefill;
  int tripsRevision = 0; // 일정을 저장하면 올라가서 "내 여행"이 다시 불러옵니다.

  void goTab(int index) {
    tab = index;
    notifyListeners();
  }

  void goExplore({String? q, String? theme, bool? indoor}) {
    exploreRequest = ExploreRequest(q: q, theme: theme, indoor: indoor);
    tab = 1;
    notifyListeners();
  }

  void goPlanner({String? prefill}) {
    plannerPrefill = prefill;
    tab = 2;
    notifyListeners();
  }

  void tripsChanged() {
    tripsRevision++;
    notifyListeners();
  }
}

/// 화면 어디서든 api · 로그인 · 찜 · 탭 컨트롤러를 꺼내 쓰게 해 주는 통로.
/// (provider 같은 패키지 없이 Flutter 기본 InheritedWidget 만 씁니다.)
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.api,
    required this.auth,
    required this.favorites,
    required this.shell,
    required this.aiKey,
    required super.child,
  });

  final ApiClient api;
  final AuthService auth;
  final FavoritesStore favorites;
  final ShellController shell;
  final AiKeyStore aiKey; // 설정 화면에 넣은 내 AI 키

  // context(위젯 트리에서의 내 위치)에서 위로 올라가며 가장 가까운 AppScope 를 찾습니다. 없으면 개발자가 알아채도록 assert 로 알립니다.
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 가 위젯 트리에 없어요.');
    return scope!;
  }

  // 안에 든 객체들은 바뀌지 않으므로 다시 그릴 필요가 없습니다.
  @override
  // false: 이 통로가 가진 객체들은 교체되지 않으므로, 이 통로 때문에 아래 화면을 다시 그릴 필요가 없습니다.
  bool updateShouldNotify(AppScope oldWidget) => false;
}

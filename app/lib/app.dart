// 앱의 뿌리 위젯 JejuApp 입니다. 위젯(Widget)은 화면 조각을 설명하는 객체이고, build 는 그 조각을 실제로 그려야 할 때 Flutter 가 부르는 함수입니다.
// 여기서 찜 보관소(FavoritesStore)를 만들고 AppScope 로 감싼 뒤, 그 안에 MaterialApp(첫 화면 HomeShell)을 둡니다.
// StatefulWidget 은 시간이 지나며 바뀌는 값(상태)을 State 객체에 들고 있는 위젯이고, StatelessWidget 은 받은 값만으로 그리는 위젯입니다.

import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app_scope.dart';
import 'auth/ai_key_store.dart';
import 'auth/auth_service.dart';
import 'auth/favorites_store.dart';
import 'brand.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

/// 앱의 뿌리. api 와 auth 를 밖에서 받으므로 테스트에서 가짜를 넣을 수 있습니다.
class JejuApp extends StatefulWidget {
  const JejuApp({super.key, required this.api, required this.auth, this.aiKey});
  final ApiClient api;
  final AuthService auth;

  /// 내 AI 키 보관소. 주지 않으면 메모리에만 두는 것을 씁니다(테스트).
  final AiKeyStore? aiKey;

  @override
  State<JejuApp> createState() => _JejuAppState();
}

// State 객체: 위젯이 화면에 떠 있는 동안 살아 있으며 아래 보관소들을 들고 있습니다.
class _JejuAppState extends State<JejuApp> {
  // late 는 "처음 쓸 때 만든다"는 뜻입니다. 그래서 widget.api 처럼 위젯이 만들어진 뒤에야 쓸 수 있는 값을 쓸 수 있습니다.
  late final ShellController _shell = ShellController();
  late final FavoritesStore _favorites = FavoritesStore(api: widget.api, auth: widget.auth);
  late final AiKeyStore _aiKey = widget.aiKey ?? AiKeyStore(MemoryKeyVault());

  // dispose 는 이 화면이 사라질 때 Flutter 가 부르는 정리 함수입니다. 직접 만든 객체는 여기서 닫아야 구독과 메모리가 새지 않습니다.
  @override
  void dispose() {
    _favorites.dispose();
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppScope 로 감싸서 아래 모든 화면이 api · 로그인 · 찜을 꺼내 쓸 수 있게 합니다.
    return AppScope(
      api: widget.api,
      auth: widget.auth,
      favorites: _favorites,
      shell: _shell,
      aiKey: _aiKey,
      child: MaterialApp(
        title: Brand.name,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}

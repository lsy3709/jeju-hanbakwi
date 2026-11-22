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

class _JejuAppState extends State<JejuApp> {
  late final ShellController _shell = ShellController();
  late final FavoritesStore _favorites = FavoritesStore(api: widget.api, auth: widget.auth);
  late final AiKeyStore _aiKey = widget.aiKey ?? AiKeyStore(MemoryKeyVault());

  @override
  void dispose() {
    _favorites.dispose();
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

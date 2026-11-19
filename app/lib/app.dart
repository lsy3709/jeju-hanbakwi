import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app_scope.dart';
import 'auth/auth_service.dart';
import 'auth/favorites_store.dart';
import 'brand.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

/// 앱의 뿌리. api 와 auth 를 밖에서 받으므로 테스트에서 가짜를 넣을 수 있습니다.
class JejuApp extends StatefulWidget {
  const JejuApp({super.key, required this.api, required this.auth});
  final ApiClient api;
  final AuthService auth;

  @override
  State<JejuApp> createState() => _JejuAppState();
}

class _JejuAppState extends State<JejuApp> {
  late final ShellController _shell = ShellController();
  late final FavoritesStore _favorites = FavoritesStore(api: widget.api, auth: widget.auth);

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
      child: MaterialApp(
        title: Brand.name,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}

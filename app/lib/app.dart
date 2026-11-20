import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app_scope.dart';
import 'brand.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

/// 앱의 뿌리. api 를 밖에서 받으므로 테스트에서 가짜를 넣을 수 있습니다.
class JejuApp extends StatefulWidget {
  const JejuApp({super.key, required this.api});
  final ApiClient api;

  @override
  State<JejuApp> createState() => _JejuAppState();
}

class _JejuAppState extends State<JejuApp> {
  late final ShellController _shell = ShellController();

  @override
  void dispose() {
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: widget.api,
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

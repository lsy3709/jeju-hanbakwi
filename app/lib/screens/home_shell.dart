import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';
import '../theme.dart';
import 'explore_screen.dart';
import 'home_screen.dart';

/// 탭 2개를 담는 틀. 좁은 화면은 하단 탭, 넓은 화면(웹)은 왼쪽 메뉴.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _tabs = [
    (icon: Icons.home_outlined, selected: Icons.home, label: '홈'),
    (icon: Icons.explore_outlined, selected: Icons.explore, label: '탐색'),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = AppScope.of(context).shell;
    return ListenableBuilder(
      listenable: shell,
      builder: (context, _) {
        // IndexedStack: 탭을 바꿔도 각 화면이 상태(검색 결과, 입력 중인 글)를 유지합니다.
        final body = IndexedStack(
          index: shell.tab,
          children: const [HomeScreen(), ExploreScreen()],
        );
        final wide = MediaQuery.sizeOf(context).width >= 768;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: shell.tab,
                  onDestinationSelected: shell.goTab,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.surface,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(Brand.name, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ),
                  destinations: [
                    for (final t in _tabs)
                      NavigationRailDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selected), label: Text(t.label)),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.line),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.tab,
            onDestinationSelected: shell.goTab,
            destinations: [
              for (final t in _tabs)
                NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selected), label: t.label),
            ],
          ),
        );
      },
    );
  }
}

// 앱의 기본 틀입니다. 탭 4개(홈 · 탐색 · AI 플래너 · 내 여행)를 담고, 화면 폭에 따라 하단 탭 또는 왼쪽 메뉴로 보여 줍니다.
// 현재 탭 번호는 ShellController(app_scope.dart)가 들고 있고, 이 파일은 그 값이 바뀔 때마다 다시 그려 탭을 바꿉니다.
// StatelessWidget 은 스스로 바뀌는 값을 갖지 않는 위젯이라 State 가 없습니다. 바뀌는 값은 바깥(ShellController)에 있습니다.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';
import '../theme.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'my_trips_screen.dart';
import 'planner_screen.dart';

/// 탭 4개를 담는 틀. 좁은 화면은 하단 탭, 넓은 화면(웹)은 왼쪽 메뉴.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  // 탭 정보를 한곳에 모아 두고 아래에서 반복해 씁니다. (icon: ..., label: ...) 모양은 이름 붙은 값 묶음(레코드)입니다.
  static const _tabs = [
    (icon: Icons.home_outlined, selected: Icons.home, label: '홈'),
    (icon: Icons.explore_outlined, selected: Icons.explore, label: '탐색'),
    (icon: Icons.auto_awesome_outlined, selected: Icons.auto_awesome, label: 'AI 플래너'),
    (icon: Icons.luggage_outlined, selected: Icons.luggage, label: '내 여행'),
  ];

  @override
  Widget build(BuildContext context) {
    // AppScope.of(context): 앱 맨 위에 둔 통로에서 탭 컨트롤러를 꺼냅니다.
    final shell = AppScope.of(context).shell;
    // ListenableBuilder 는 listenable(여기서는 shell)이 notifyListeners() 로 알릴 때마다 builder 를 다시 실행해 화면을 다시 그립니다. 탭 번호가 바뀌면 이 부분이 새로 그려집니다.
    return ListenableBuilder(
      listenable: shell,
      builder: (context, _) {
        // IndexedStack: 탭을 바꿔도 각 화면이 상태(검색 결과, 입력 중인 글)를 유지합니다.
        // IndexedStack: 네 화면을 모두 만들어 두고 index 번째만 보여 줍니다. 탭을 오가도 각 화면이 지워지지 않고 상태(검색 결과, 쓰던 글)가 남습니다.
        final body = IndexedStack(
          index: shell.tab,
          children: const [HomeScreen(), ExploreScreen(), PlannerScreen(), MyTripsScreen()],
        );
        // MediaQuery.sizeOf(context).width: 지금 화면의 가로 폭입니다. 768 이상이면 넓은 화면(웹)으로 보고 왼쪽 메뉴를 씁니다.
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

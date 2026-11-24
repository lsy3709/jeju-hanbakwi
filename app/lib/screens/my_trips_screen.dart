// 네 번째 탭 "내 여행" 화면입니다. 로그인하지 않았으면 안내와 로그인 버튼을, 로그인했으면 [찜한 곳 | 저장한 일정] 두 탭을 보여 줍니다.
// 로그인 상태는 AuthService(auth/auth_service.dart)가 알려 주고, 두 탭의 실제 내용은 my_trips/ 폴더의 파일에 있습니다.
// _ 로 시작하는 클래스(_LoggedOutView)는 이 파일 안에서만 쓰는 비공개 위젯입니다.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';
import '../theme.dart';
import '../widgets/login_prompt.dart';
import '../widgets/state_views.dart';
import 'my_trips/favorites_tab.dart';
import 'my_trips/trips_tab.dart';

/// 내 여행 화면: 로그인 전엔 안내, 로그인 후엔 [찜한 곳 | 저장한 일정] 탭.
/// 두 탭의 내용은 `my_trips/` 폴더에 있습니다.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return SafeArea(
      child: CenteredBody(
        maxWidth: 900,
        // 로그인·로그아웃이 일어나면 화면이 저절로 바뀝니다.
        // auth 가 바뀌면(로그인·로그아웃) builder 가 다시 실행되어 두 화면 중 맞는 쪽으로 저절로 바뀝니다.
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, _) => auth.loggedIn ? const _LoggedInView() : const _LoggedOutView(),
        ),
      ),
    );
  }
}

/// 로그인 전: 안내 문구와 "구글로 로그인" 버튼.
class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('내 여행', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              '로그인하면 마음에 든 곳을 찜하고,\nAI가 짜 준 일정을 저장해 둘 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            if (auth.configured)
              FilledButton.icon(
                // 로그인 시작은 기다려야 하는 일이라 async 입니다. 실패해도 앱이 죽지 않게 try/catch 로 잡고, 화면이 아직 있을 때(context.mounted)만 안내를 띄웁니다.
                onPressed: () async {
                  try {
                    await auth.signInWithGoogle();
                  } catch (_) {
                    if (context.mounted) showSnack(context, '로그인을 시작하지 못했어요. 잠시 후 다시 시도해 주세요.');
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('구글로 로그인'),
              )
            else
              // if / else 로 "설정이 있을 때는 버튼, 없을 때는 안내"를 고릅니다.
              // Supabase 설정 값이 비어 있는 수업 초반: 앱은 죽지 않고 안내만 보여 줍니다.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Text(Brand.loginNotReady, style: TextStyle(color: AppColors.muted)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 로그인 후: 계정 줄 + 두 탭.
class _LoggedInView extends StatelessWidget {
  const _LoggedInView();

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    // DefaultTabController 가 TabBar(윗줄 이름표)와 TabBarView(아래 내용)를 서로 연결해 줍니다. length 는 탭 개수입니다.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(auth.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                TextButton(onPressed: auth.signOut, child: const Text('로그아웃')),
              ],
            ),
          ),
          const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: '찜한 곳'),
              Tab(text: '저장한 일정'),
            ],
          ),
          const Expanded(child: TabBarView(children: [FavoritesTab(), TripsTab()])),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../brand.dart';
import '../models/spot.dart';
import '../models/trip.dart';
import '../theme.dart';
import '../widgets/itinerary_view.dart';
import '../widgets/login_prompt.dart';
import '../widgets/spot_card.dart';
import '../widgets/state_views.dart';
import 'spot_detail_screen.dart';

/// 내 여행: 로그인 전엔 안내, 로그인 후엔 [찜한 곳 | 저장한 일정] 탭.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return SafeArea(
      child: CenteredBody(
        maxWidth: 900,
        // 로그인·로그아웃이 일어나면 화면이 저절로 바뀝니다.
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, _) => auth.loggedIn ? const _LoggedInView() : const _LoggedOutView(),
        ),
      ),
    );
  }
}

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

class _LoggedInView extends StatelessWidget {
  const _LoggedInView();

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
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
            tabs: [Tab(text: '찜한 곳'), Tab(text: '저장한 일정')],
          ),
          const Expanded(child: TabBarView(children: [_FavoritesTab(), _TripsTab()])),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
        if (favorites.loading && favorites.items.isEmpty) return const LoadingView();
        if (favorites.error != null) return ErrorView(message: favorites.error!, onRetry: favorites.refresh);
        if (favorites.items.isEmpty) {
          return const EmptyView(message: '아직 찜한 곳이 없어요.\n마음에 드는 곳에서 하트를 눌러 보세요.', icon: Icons.favorite_border);
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisExtent: SpotCard.height,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: favorites.items.length,
          itemBuilder: (context, i) {
            final Spot spot = favorites.items[i];
            return SpotCard(
              spot: spot,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spotId: spot.id, initial: spot)),
              ),
              corner: IconButton.filledTonal(
                tooltip: '찜 해제',
                icon: const Icon(Icons.favorite, color: AppColors.primary),
                onPressed: () async {
                  try {
                    await favorites.toggle(spot);
                  } on ApiException catch (e) {
                    if (context.mounted) showSnack(context, e.message);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TripsTab extends StatefulWidget {
  const _TripsTab();

  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  List<Trip> _trips = [];
  bool _loading = true;
  String? _error;
  ShellController? _shell;
  int _seenRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shell == null) {
      _shell = AppScope.of(context).shell;
      _seenRevision = _shell!.tripsRevision;
      _shell!.addListener(_onShellChanged);
      _load();
    }
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShellChanged);
    super.dispose();
  }

  // AI 플래너에서 일정을 저장하면 목록을 다시 불러옵니다.
  void _onShellChanged() {
    if (_shell!.tripsRevision != _seenRevision) {
      _seenRevision = _shell!.tripsRevision;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await AppScope.of(context).api.getTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _delete(Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('일정을 삭제할까요?'),
        content: Text('"${trip.title}" 일정이 사라져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).api.deleteTrip(trip.id);
      if (mounted) setState(() => _trips = _trips.where((t) => t.id != trip.id).toList());
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_trips.isEmpty) {
      return const EmptyView(message: '저장한 일정이 없어요.\nAI 플래너에서 일정을 짜고 저장해 보세요.', icon: Icons.bookmark_border);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final trip = _trips[i];
        final date = trip.savedDate;
        return Card(
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('$date · ${trip.itinerary.length}일 일정', style: const TextStyle(color: AppColors.muted)),
            trailing: IconButton(tooltip: '삭제', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(trip)),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              ItineraryView(
                days: trip.itinerary,
                onSpotTap: (id) => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spotId: id)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

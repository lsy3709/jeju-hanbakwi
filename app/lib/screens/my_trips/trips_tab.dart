import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../controllers/trips_controller.dart';
import '../../models/trip.dart';
import '../../theme.dart';
import '../../widgets/itinerary_view.dart';
import '../../widgets/load_more_footer.dart';
import '../../widgets/login_prompt.dart';
import '../../widgets/state_views.dart';
import '../spot_detail_screen.dart';

/// "내 여행 > 저장한 일정" 탭. 목록 불러오기·삭제는 [TripsController] 가 하고, 이 탭은 그립니다.
class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  late final TripsController _controller;
  late final ShellController _shell;
  int _seenRevision = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope 는 initState 에서 못 꺼내므로, 처음 한 번만 여기서 준비합니다.
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    _controller = TripsController(api: scope.api)..load();
    _shell = scope.shell;
    _seenRevision = _shell.tripsRevision;
    _shell.addListener(_onShellChanged);
  }

  @override
  void dispose() {
    _shell.removeListener(_onShellChanged);
    _controller.dispose();
    super.dispose();
  }

  /// AI 플래너에서 일정을 저장하면 목록을 다시 불러옵니다.
  void _onShellChanged() {
    if (_shell.tripsRevision != _seenRevision) {
      _seenRevision = _shell.tripsRevision;
      _controller.load();
    }
  }

  Future<void> _loadMore() async {
    final message = await _controller.loadMore();
    if (message != null && mounted) showSnack(context, message);
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
    final message = await _controller.delete(trip);
    if (message != null && mounted) showSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        if (c.loading) return const LoadingView();
        if (c.error != null) return ErrorView(message: c.error!, onRetry: c.load);
        if (c.trips.isEmpty) {
          return const EmptyView(message: '저장한 일정이 없어요.\nAI 플래너에서 일정을 짜고 저장해 보세요.', icon: Icons.bookmark_border);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.trips.length + 1, // 마지막 한 칸은 "더 보기" 자리
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == c.trips.length) {
              return LoadMoreFooter(hasMore: c.hasMore, loadingMore: c.loadingMore, onPressed: _loadMore);
            }
            final trip = c.trips[i];
            return Card(
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${trip.savedDate} · ${trip.itinerary.length}일 일정',
                  style: const TextStyle(color: AppColors.muted),
                ),
                trailing: IconButton(
                  tooltip: '삭제',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(trip),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  ItineraryView(
                    days: trip.itinerary,
                    onSpotTap: (id) => SpotDetailScreen.open(context, spotId: id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

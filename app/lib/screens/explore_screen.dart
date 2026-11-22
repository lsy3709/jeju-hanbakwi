import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';
import '../controllers/explore_controller.dart';
import '../models/spot.dart';
import '../theme.dart';
import '../widgets/filter_menu.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/login_prompt.dart';
import '../widgets/spot_card.dart';
import '../widgets/spot_map.dart';
import '../widgets/state_views.dart';
import 'spot_detail_screen.dart';

/// 탐색 화면: 검색바 · 테마 칩 · 필터 → 카드 그리드 ↔ 지도, 20개씩 "더 보기".
/// 검색 조건과 목록은 [ExploreController] 가 들고 있고, 이 화면은 그것을 그리기만 합니다.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  bool _mapMode = false; // 목록 ↔ 지도는 화면 모양일 뿐이라 컨트롤러가 아닌 여기에 둡니다.

  late final ExploreController _controller;
  late final ShellController _shell;
  ExploreRequest? _lastRequest;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope 는 initState 에서 못 꺼내므로, 처음 한 번만 여기서 준비합니다.
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    _controller = ExploreController(api: scope.api)..start();
    _shell = scope.shell..addListener(_onShellChanged);
  }

  @override
  void dispose() {
    _shell.removeListener(_onShellChanged);
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  /// 홈에서 "이 조건으로 찾아 줘" 하고 보낸 요청이 오면 조건을 바꿔 다시 검색합니다.
  void _onShellChanged() {
    final request = _shell.exploreRequest;
    if (request == null || identical(request, _lastRequest)) return;
    _lastRequest = request;
    _search.text = request.q ?? '';
    _controller.applyRequest(q: request.q, theme: request.theme, indoor: request.indoor);
  }

  Future<void> _loadMore() async {
    final message = await _controller.loadMore();
    if (message != null && mounted) showSnack(context, message);
  }

  void _openDetail(Spot spot) => SpotDetailScreen.open(context, spotId: spot.id, initial: spot);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CenteredBody(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            children: [
              _header(),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final c = _controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchPill(controller: _search, hint: Brand.searchHint, onSubmitted: c.search),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in c.meta?.themes ?? const <String>[])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: c.theme == t,
                      // 같은 칩을 다시 누르면 선택 해제
                      onSelected: (on) => c.setTheme(on ? t : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterMenu(label: '지역', value: c.area, options: c.meta?.areas ?? const [], onChanged: c.setArea),
              FilterMenu(
                label: '분류',
                value: c.category,
                options: c.meta?.categories ?? const [],
                onChanged: c.setCategory,
              ),
              SegmentedButton<bool?>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: null, label: Text('전체')),
                  ButtonSegment(value: true, label: Text('실내')),
                  ButtonSegment(value: false, label: Text('실외')),
                ],
                selected: {c.indoor},
                onSelectionChanged: (s) => c.setIndoor(s.first),
              ),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.grid_view), label: Text('목록')),
                  ButtonSegment(value: true, icon: Icon(Icons.map_outlined), label: Text('지도')),
                ],
                selected: {_mapMode},
                onSelectionChanged: (s) => setState(() => _mapMode = s.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final c = _controller;
    if (c.loading) return const LoadingView();
    if (c.error != null) return ErrorView(message: c.error!, onRetry: c.reload);
    if (c.items.isEmpty) {
      return const EmptyView(message: '조건에 맞는 곳이 없어요.\n검색어나 필터를 바꿔 보세요.');
    }
    if (_mapMode) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SpotMap(spots: c.items, onOpen: _openDetail),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('총 ${c.total}곳', style: const TextStyle(color: AppColors.muted)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // 가로 폭에 맞춰 열 수가 저절로 정해집니다(좁은 화면 1~2열, 웹 3~4열).
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: SpotCard.height,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: c.items.length,
            itemBuilder: (context, i) => SpotCard(spot: c.items[i], onTap: () => _openDetail(c.items[i])),
          ),
        ),
        SliverToBoxAdapter(
          child: LoadMoreFooter(hasMore: c.hasMore, loadingMore: c.loadingMore, onPressed: _loadMore),
        ),
      ],
    );
  }
}

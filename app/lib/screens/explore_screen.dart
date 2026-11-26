// 두 번째 탭인 탐색 화면입니다. 검색 · 테마 칩 · 필터로 관광지를 찾고, 카드 목록과 지도를 오가며 보여 줍니다.
// 검색 조건과 목록은 ExploreController 가 들고 있고, 이 화면은 그 값을 그리고 사용자의 조작(입력, 칩 누르기)을 컨트롤러에 전달합니다.
// 홈에서 넘어온 검색 요청은 ShellController 를 통해 받습니다(_onShellChanged).

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';
import '../config.dart';
import '../controllers/explore_controller.dart';
import '../map3d.dart';
import '../models/spot.dart';
import '../theme.dart';
import '../widgets/filter_menu.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/login_prompt.dart';
import '../widgets/spot_card.dart';
import '../widgets/spot_map.dart';
import '../widgets/spot_map_3d.dart';
import '../widgets/state_views.dart';
import 'spot_detail_screen.dart';

/// 보는 방식: 목록 · 지도(앱이 그림) · 3D 지도 · 판타지 지도(둘은 웹 화면을 띄움)
enum _View { list, map, map3d, fantasy }

/// 탐색 화면: 검색바 · 테마 칩 · 필터 → 카드 그리드 ↔ 지도 ↔ 3D 지도, 20개씩 "더 보기".
/// 검색 조건과 목록은 [ExploreController] 가 들고 있고, 이 화면은 그것을 그리기만 합니다.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  // 보는 방식(목록 · 지도 · 3D)은 화면 모양일 뿐이라 컨트롤러가 아닌 여기에 둡니다. 바꿀 때는 setState 를 불러야 다시 그려집니다.
  _View _view = _View.list;

  late final ExploreController _controller;
  late final ShellController _shell;
  ExploreRequest? _lastRequest;
  bool _started = false;

  @override
  // AppScope 를 꺼낼 수 있는 첫 시점에 한 번만(_started) 컨트롤러를 만들고 탭 이동 소식을 듣기 시작합니다. 듣기는 dispose 에서 끊습니다.
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
  // 홈에서 탐색 탭으로 조건을 보내면 이 함수가 불립니다. 같은 요청(identical)이면 두 번 처리하지 않습니다.
  void _onShellChanged() {
    final request = _shell.exploreRequest;
    if (request == null || identical(request, _lastRequest)) return;
    _lastRequest = request;
    _search.text = request.q ?? '';
    _controller.applyRequest(q: request.q, theme: request.theme, indoor: request.indoor);
  }

  // await 가 끝난 뒤 화면이 이미 닫혔을 수 있어서, 안내 글을 띄우기 전에 mounted(아직 화면에 있는가)를 확인합니다.
  Future<void> _loadMore() async {
    final message = await _controller.loadMore();
    if (message != null && mounted) showSnack(context, message);
  }

  void _openDetail(Spot spot) => SpotDetailScreen.open(context, spotId: spot.id, initial: spot);

  @override
  // 컨트롤러의 값이 바뀔 때마다 ListenableBuilder 안쪽(머리글 + 본문)이 다시 그려집니다.
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

  // 검색창 · 테마 칩 · 필터 · 보기 전환을 모은 윗부분입니다. 필터를 바꾸면 컨트롤러가 처음부터 다시 검색합니다.
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
                options: c.meta?.allCategories ?? const [],
                onChanged: c.setCategory,
              ),
              // <bool?> 는 선택 값이 true / false / null(전체) 중 하나라는 뜻입니다.
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
              SegmentedButton<_View>(
                showSelectedIcon: false,
                // 네 칸이 휴대폰 폭에 한 줄로 들어가게 안쪽 여백을 줄이고, 글자가 두 줄로 꺾이지 않게 합니다.
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                ),
                segments: const [
                  ButtonSegment(value: _View.list, icon: Icon(Icons.grid_view, size: 18), label: Text('목록', softWrap: false)),
                  ButtonSegment(value: _View.map, icon: Icon(Icons.map_outlined, size: 18), label: Text('지도', softWrap: false)),
                  ButtonSegment(value: _View.map3d, icon: Icon(Icons.terrain, size: 18), label: Text('3D', softWrap: false)),
                  ButtonSegment(value: _View.fantasy, icon: Icon(Icons.auto_stories_outlined, size: 18), label: Text('판타지', softWrap: false)),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 상태에 따라 하나만 고릅니다: 로딩 → 오류 → 비어 있음 → 지도 → 카드 목록. 위에서부터 차례로 확인해 먼저 해당하는 것을 돌려줍니다.
  Widget _body() {
    final c = _controller;
    if (_view == _View.map3d || _view == _View.fantasy) {
      // 3D 지도와 판타지 지도는 웹에서 만든 화면을 띄웁니다. 고른 필터를 주소에 실어 보내면 웹이 같은 조건으로 다시 찾습니다.
      final url = map3dUrl(Config.webUrl, q: c.query, theme: c.theme, area: c.area, category: c.category, indoor: c.indoor, fantasy: _view == _View.fantasy);
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.card), child: SpotMap3d(url: url)),
      );
    }
    if (c.loading) return const LoadingView();
    if (c.error != null) return ErrorView(message: c.error!, onRetry: c.reload);
    if (c.items.isEmpty) {
      return const EmptyView(message: '조건에 맞는 곳이 없어요.\n검색어나 필터를 바꿔 보세요.');
    }
    if (_view == _View.map) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SpotMap(spots: c.items, onOpen: _openDetail),
        ),
      );
    }
    // Sliver 는 스크롤 영역의 조각입니다. 개수 안내, 카드 그리드, "더 보기" 버튼을 한 번에 이어서 스크롤하게 합니다.
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

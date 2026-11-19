import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../brand.dart';
import '../models/spot.dart';
import '../theme.dart';
import '../widgets/spot_card.dart';
import '../widgets/spot_map.dart';
import '../widgets/state_views.dart';
import 'spot_detail_screen.dart';

/// 탐색: 검색바 · 테마 칩 · 필터 → 카드 그리드 ↔ 지도, 20개씩 "더 보기".
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  String? _theme;
  String? _area;
  String? _category;
  bool? _indoor; // null = 전체
  bool _mapMode = false;

  Meta? _meta;
  List<Spot> _items = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  ShellController? _shell;
  ExploreRequest? _lastRequest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shell == null) {
      _shell = AppScope.of(context).shell;
      _shell!.addListener(_onShellChanged);
      _loadMeta();
      _fetch();
    }
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShellChanged);
    _search.dispose();
    super.dispose();
  }

  /// 홈에서 "이 조건으로 찾아 줘" 하고 보낸 요청이 오면 조건을 바꿔 다시 검색합니다.
  void _onShellChanged() {
    final request = _shell!.exploreRequest;
    if (request == null || identical(request, _lastRequest)) return;
    _lastRequest = request;
    setState(() {
      _search.text = request.q ?? '';
      _theme = request.theme;
      _indoor = request.indoor;
      _area = null;
      _category = null;
    });
    _fetch();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await AppScope.of(context).api.getMeta();
      if (mounted) setState(() => _meta = meta);
    } on ApiException {
      // 선택지를 못 받아도 검색은 됩니다. 칩이 비어 보일 뿐입니다.
    }
  }

  /// 첫 쪽부터 다시 검색.
  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _query(1);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _total = page.total;
        _page = 1;
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

  /// "더 보기": 다음 쪽을 이어 붙입니다.
  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await _query(_page + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _total = page.total;
        _page = page.page;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<SpotPage> _query(int page) {
    return AppScope.of(context).api.getSpots(
          q: _search.text,
          theme: _theme,
          area: _area,
          category: _category,
          indoor: _indoor,
          page: page,
          size: _pageSize,
        );
  }

  void _openDetail(Spot spot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spotId: spot.id, initial: spot)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CenteredBody(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final themes = _meta?.themes ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchPill(controller: _search, hint: Brand.searchHint, onSubmitted: (_) => _fetch()),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in themes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _theme == t,
                      labelStyle: TextStyle(color: _theme == t ? Colors.white : AppColors.ink),
                      // 같은 칩을 다시 누르면 선택 해제
                      onSelected: (on) {
                        setState(() => _theme = on ? t : null);
                        _fetch();
                      },
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
              _FilterMenu(
                label: '지역',
                value: _area,
                options: _meta?.areas ?? const [],
                onChanged: (v) {
                  setState(() => _area = v);
                  _fetch();
                },
              ),
              _FilterMenu(
                label: '분류',
                value: _category,
                options: _meta?.categories ?? const [],
                onChanged: (v) {
                  setState(() => _category = v);
                  _fetch();
                },
              ),
              SegmentedButton<bool?>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: null, label: Text('전체')),
                  ButtonSegment(value: true, label: Text('실내')),
                  ButtonSegment(value: false, label: Text('실외')),
                ],
                selected: {_indoor},
                onSelectionChanged: (s) {
                  setState(() => _indoor = s.first);
                  _fetch();
                },
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
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _fetch);
    if (_items.isEmpty) {
      return const EmptyView(message: '조건에 맞는 곳이 없어요.\n검색어나 필터를 바꿔 보세요.');
    }
    if (_mapMode) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SpotMap(spots: _items, onOpen: _openDetail),
        ),
      );
    }
    final hasMore = _items.length < _total;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('총 $_total곳', style: const TextStyle(color: AppColors.muted)),
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
            itemCount: _items.length,
            itemBuilder: (context, i) => SpotCard(spot: _items[i], onTap: () => _openDetail(_items[i])),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: hasMore
                  ? (_loadingMore
                      ? const CircularProgressIndicator()
                      : OutlinedButton(onPressed: _loadMore, child: const Text('더 보기')))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

/// "지역 ▾" 처럼 알약 모양으로 보이는 선택 메뉴. 고르면 라벨이 선택값으로 바뀝니다.
class _FilterMenu extends StatelessWidget {
  const _FilterMenu({required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return PopupMenuButton<String>(
      tooltip: '$label 고르기',
      // 빈 문자열 = "전체"(조건 해제)
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (context) => [
        PopupMenuItem(value: '', child: Text('$label 전체')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value ?? label, style: TextStyle(color: selected ? Colors.white : AppColors.ink)),
            Icon(Icons.arrow_drop_down, size: 20, color: selected ? Colors.white : AppColors.muted),
          ],
        ),
      ),
    );
  }
}

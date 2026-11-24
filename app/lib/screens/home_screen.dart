// 첫 탭인 홈 화면입니다. 불러오기와 상태는 HomeController 가 하고, 이 화면은 그 값(로딩 · 오류 · 목록)을 보고 그리기만 합니다.
// 이 파일의 흐름: 화면 → HomeController(controllers/home_controller.dart) → ApiClient.
// StatefulWidget 은 State 객체에 바뀌는 값과 정리(dispose)가 필요한 객체(컨트롤러, 입력창)를 둘 때 씁니다.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';
import '../controllers/home_controller.dart';
import '../theme.dart';
import '../widgets/spot_card.dart';
import '../widgets/state_views.dart';
import '../widgets/weather_banner.dart';
import 'spot_detail_screen.dart';

/// 홈 화면: 인사 + 검색 → 날씨 배너 → 테마 칩 → "지금 가기 좋은 곳" → AI 안내 카드.
/// 불러오기는 [HomeController] 가 하고, 이 화면은 그리기만 합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// TextEditingController 는 입력창의 글을 읽고 바꾸는 도구라서 dispose 에서 꼭 닫아 줘야 합니다.
class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late final HomeController _controller;
  bool _started = false;

  @override
  // initState 때는 아직 AppScope 를 꺼낼 수 없어서 여기서 준비합니다. 이 함수는 여러 번 불릴 수 있어 _started 로 처음 한 번만 하게 막습니다. ..load() 는 만든 컨트롤러에 바로 load() 를 부르는 문법입니다.
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope 는 initState 에서 못 꺼내므로, 처음 한 번만 여기서 불러옵니다.
    if (_started) return;
    _started = true;
    _controller = HomeController(api: AppScope.of(context).api)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  // ListenableBuilder 가 컨트롤러를 듣고 있다가 값이 바뀌면 이 안쪽만 다시 그립니다. 안쪽은 loading → 로딩 화면, error → 오류 화면, 아니면 목록 순으로 고릅니다(조건 ? A : B 를 이어 쓴 것).
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _controller.loading
            ? const LoadingView()
            : _controller.error != null
            ? ErrorView(message: _controller.error!, onRetry: _controller.load)
            : RefreshIndicator(
                // RefreshIndicator 는 목록을 아래로 당기면 onRefresh 를 부르고, 그 Future 가 끝날 때까지 로딩 표시를 보여 줍니다.
                onRefresh: _controller.load,
                child: CenteredBody(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: [
                      Text(
                        Brand.greeting,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      SearchPill(
                        controller: _search,
                        hint: Brand.searchHint,
                        onSubmitted: (text) => scope.shell.goExplore(q: text),
                      ),
                      const SizedBox(height: 20),
                      WeatherBanner(weather: _controller.weather, onIndoor: () => scope.shell.goExplore(indoor: true)),
                      const SizedBox(height: 24),
                      _themeChips(scope),
                      const SizedBox(height: 24),
                      Text(
                        '지금 가기 좋은 곳',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _spotList(),
                      const SizedBox(height: 24),
                      _aiCard(scope),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // _controller.meta?.themes ?? const <String>[] : meta 가 없으면(null) 빈 목록으로 대신합니다. 칩을 누르면 탐색 탭으로 이동하며 그 테마로 검색합니다.
  Widget _themeChips(AppScope scope) {
    final themes = _controller.meta?.themes ?? const <String>[];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(themes[i]),
          onPressed: () => scope.shell.goExplore(theme: themes[i]),
        ),
      ),
    );
  }

  // 가로로 넘기는 카드 목록입니다. itemBuilder 는 i 번째 칸이 필요할 때마다 호출되어 화면에 보이는 것만 만듭니다.
  Widget _spotList() {
    if (_controller.spots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('아직 보여 드릴 곳이 없어요.', style: TextStyle(color: AppColors.muted)),
      );
    }
    return SizedBox(
      height: SpotCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.spots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final spot = _controller.spots[i];
          return SizedBox(
            width: 230,
            child: SpotCard(
              spot: spot,
              onTap: () => SpotDetailScreen.open(context, spotId: spot.id, initial: spot),
            ),
          );
        },
      ),
    );
  }

  // 누르면 AI 플래너 탭으로 이동합니다.
  Widget _aiCard(AppScope scope) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => scope.shell.goPlanner(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Brand.aiCardTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(Brand.aiCardBody, style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

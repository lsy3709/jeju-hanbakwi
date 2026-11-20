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

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late final HomeController _controller;
  bool _started = false;

  @override
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

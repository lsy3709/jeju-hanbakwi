import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../brand.dart';
import '../models/spot.dart';
import '../models/weather.dart';
import '../theme.dart';
import '../widgets/spot_card.dart';
import '../widgets/state_views.dart';
import 'spot_detail_screen.dart';

/// 홈: 인사 + 검색 → 날씨 배너 → 테마 칩 → "지금 가기 좋은 곳" → AI 안내 카드.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  bool _loading = true;
  String? _error;
  Meta? _meta;
  Weather? _weather; // 날씨는 실패해도 홈 전체를 막지 않습니다(null 이면 안내만).
  List<Spot> _spots = [];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope 는 initState 에서 못 꺼내므로, 처음 한 번만 여기서 불러옵니다.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = AppScope.of(context).api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Weather? weather;
      try {
        weather = await api.getWeather();
      } on ApiException {
        weather = null; // 날씨 서비스가 503 이어도 계속 진행
      }
      final meta = await api.getMeta();
      // 비 오는 날은 실내, 아니면 실외 관광지를 먼저 보여 줍니다.
      final page = await api.getSpots(indoor: weather?.rainyToday == true, size: 8);
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _meta = meta;
        _spots = page.items;
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

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return SafeArea(
      child: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
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
                        _WeatherBanner(
                          weather: _weather,
                          onIndoor: () => scope.shell.goExplore(indoor: true),
                        ),
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
    );
  }

  Widget _themeChips(AppScope scope) {
    final themes = _meta?.themes ?? const <String>[];
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
    if (_spots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('아직 보여 드릴 곳이 없어요.', style: TextStyle(color: AppColors.muted)),
      );
    }
    return SizedBox(
      height: SpotCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _spots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final spot = _spots[i];
          return SizedBox(
            width: 230,
            child: SpotCard(
              spot: spot,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spotId: spot.id, initial: spot)),
              ),
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

/// 날씨 배너: 서버가 준 한 줄 메시지 + 오늘 제주시·서귀포시 날씨.
class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner({required this.weather, required this.onIndoor});
  final Weather? weather;
  final VoidCallback onIndoor;

  static IconData _icon(String name) => switch (name) {
        'sun' => Icons.wb_sunny,
        'cloud' => Icons.cloud,
        'rain' => Icons.umbrella,
        'snow' => Icons.ac_unit,
        'fog' => Icons.foggy,
        _ => Icons.wb_cloudy,
      };

  @override
  Widget build(BuildContext context) {
    final w = weather;
    return Card(
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: w == null
            ? const Text('날씨를 불러오지 못했어요. 그래도 여행지는 둘러볼 수 있어요.', style: TextStyle(color: AppColors.muted))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.message, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      for (final a in w.areas)
                        if (a.days.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icon(a.days.first.icon), color: AppColors.secondary),
                              const SizedBox(width: 6),
                              Text(
                                // 서버가 기온을 null 로 줄 수 있어, 값이 없으면 기온 조각은 뺍니다.
                                [
                                  a.area,
                                  a.days.first.label,
                                  if (a.days.first.tempMin != null && a.days.first.tempMax != null)
                                    '${a.days.first.tempMin!.round()}~${a.days.first.tempMax!.round()}°',
                                ].join(' '),
                              ),
                            ],
                          ),
                    ],
                  ),
                  if (w.rainyToday) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: onIndoor, child: const Text('실내 코스 보기')),
                  ],
                ],
              ),
      ),
    );
  }
}

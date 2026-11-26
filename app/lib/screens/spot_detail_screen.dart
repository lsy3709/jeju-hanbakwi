// 관광지 한 곳의 상세 화면입니다. 홈 · 탐색 · 찜 · 일정 어디서든 SpotDetailScreen.open 한 줄로 엽니다.
// 목록에서 넘어올 때는 이미 받은 Spot 을 먼저 보여 주고(initial), 일정처럼 id 만 있을 때는 ApiClient.getSpot 으로 불러옵니다.
// 하트는 FavoritesStore 가 들고 있어서 찜 탭과 같은 값을 봅니다.

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../format.dart';
import '../models/spot.dart';
import '../theme.dart';
import '../widgets/login_prompt.dart';
import '../widgets/spot_image.dart';
import '../widgets/spot_map.dart';
import '../widgets/state_views.dart';

/// 관광지 상세 화면. 다른 화면에서는 [SpotDetailScreen.open] 으로 엽니다.
/// 상세: 큰 사진 → 분류·지역 → 제목 → 한 줄 소개 → 태그 → 실내/실외 → 소개 → 주소 → 지도 → 버튼 2개 → 근처 추천 식당.
class SpotDetailScreen extends StatefulWidget {
  /// [initial] 이 있으면 먼저 보여 주고(목록에서 넘어온 경우), 없으면 서버에서 불러옵니다.
  // Spot? initial 의 ? 는 없을 수도 있다는 뜻입니다. 있으면 서버를 기다리지 않고 바로 그립니다.
  const SpotDetailScreen({super.key, required this.spotId, this.initial});
  final int spotId;
  final Spot? initial;

  /// 상세 화면을 엽니다. 어느 화면에서든 이 한 줄로 부르게 해, 화면 이동 코드가 여기 한 곳에만 있게 합니다.
  /// 이미 가진 [initial] 을 넘기면 서버를 기다리지 않고 바로 보여 줍니다.
  static Future<void> open(BuildContext context, {required int spotId, Spot? initial}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spotId: spotId, initial: initial)),
    );
  }

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  Spot? _spot;
  String? _error;
  bool _loading = false;
  // didChangeDependencies 는 여러 번 불릴 수 있어서, 처음 한 번만 준비하게 막는 표시입니다.
  bool _started = false;
  List<NearbySpot> _foods = const []; // 근처 추천 식당. 못 받으면 빈 목록(그 부분만 안 보임)

  @override
  // State 의 widget.xxx 로 위젯이 받은 값(spotId, initial)을 읽습니다. 목록에서 넘어왔으면 그대로 보여 주고 아니면 _load 로 서버에서 불러옵니다.
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _spot = widget.initial;
      // 하트가 맞게 보이도록, 받아 둔 찜 목록에 없으면 서버에 한 번 묻습니다.
      AppScope.of(context).favorites.check(widget.spotId);
      // 목록에서 넘어왔으면 그 내용을 바로 보여 주고, 아니면(일정·딥링크 등) 서버에서 불러옵니다.
      if (_spot == null) _load();
      _loadFoods();
    }
  }

  /// 근처 추천 식당을 받습니다. 실패해도(옛 서버 · 데이터 없음) 상세의 다른 부분은 그대로 보여야 하므로 조용히 넘어갑니다.
  Future<void> _loadFoods() async {
    try {
      final foods = await AppScope.of(context).api.getNearbyRestaurants(widget.spotId);
      if (mounted) setState(() => _foods = foods);
    } on Object {
      // 식당 목록은 덤입니다. 못 받으면 그리지 않습니다.
    }
  }

  // 불러오는 동안 _loading 을 켜고, 끝나면 setState 로 결과(또는 오류)를 반영합니다. 기다린 사이 화면이 닫혔으면(mounted 아님) 아무것도 하지 않습니다.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spot = await AppScope.of(context).api.getSpot(widget.spotId);
      if (!mounted) return;
      setState(() {
        _spot = spot;
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

  // 찜은 로그인이 필요해서 로그인하지 않았으면 안내 창을 띄웁니다. 서버 요청이 실패하면 서버 문구를 안내로 보여 줍니다.
  Future<void> _toggleFavorite(Spot spot) async {
    final scope = AppScope.of(context);
    if (!scope.auth.loggedIn) {
      await showLoginPrompt(context);
      return;
    }
    try {
      await scope.favorites.toggle(spot);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  // 상태를 차례로 확인합니다: 불러오는 중 → 관광지가 없음(오류) → 내용. _error ?? '…' 는 오류 문구가 없으면 기본 문구를 씁니다.
  Widget build(BuildContext context) {
    final spot = _spot;
    return Scaffold(
      appBar: AppBar(),
      body: _loading
          ? const LoadingView()
          : spot == null
              ? ErrorView(message: _error ?? '관광지를 찾을 수 없어요.', onRetry: _load)
              : _content(spot),
    );
  }

  // 위에서 아래로 사진 → 분류 → 제목 → 소개 → 태그 → 주소 → 지도 → 버튼 순으로 쌓은 목록입니다.
  Widget _content(Spot spot) {
    final scope = AppScope.of(context);
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);
    return CenteredBody(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SpotImage(spot: spot, height: 240, iconSize: 64),
          ),
          // spot.imageCredit?.trim().isNotEmpty ?? false : ?. 는 값이 없으면 건너뛰고, ?? false 는 그때 "없음"으로 취급합니다.
          // 공개 라이선스 사진은 출처를 밝혀야 쓸 수 있어요. 사진이 없으면(대체 그림) 밝힐 출처도 없습니다.
          if (spot.imageUrl != null && (spot.imageCredit?.trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('사진: ${spot.imageCredit!.trim()}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          const SizedBox(height: 16),
          Text('${spot.category} · ${spot.area}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(spot.title, style: titleStyle),
          const SizedBox(height: 8),
          Text(spot.oneLiner, style: const TextStyle(fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in spot.themeTags)
                Chip(
                  label: Text('#$tag'),
                  labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 13),
                  visualDensity: VisualDensity.compact,
                ),
              Chip(
                avatar: Icon(spot.indoor ? Icons.roofing : Icons.wb_sunny_outlined, size: 18, color: AppColors.secondary),
                label: Text(spot.indoor ? '실내' : '실외'),
                labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 13),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (spot.overview.isNotEmpty) Text(spot.overview, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 20, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(spot.address, style: const TextStyle(color: AppColors.muted))),
            ],
          ),
          // 위치가 없는 곳(관리자가 위치 없이 추가)은 지도를 그리지 않습니다.
          // 위치가 없는 곳은 지도 칸 전체를 만들지 않습니다.
          if (spot.hasLocation) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                // 작은 지도는 보기만 합니다(스크롤을 방해하지 않도록 조작 끔).
                child: SpotMap(spots: [spot], interactive: false, zoom: 13),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ListenableBuilder(
                listenable: scope.favorites,
                builder: (context, _) {
                  final fav = scope.favorites.isFavorite(spot.id);
                  return OutlinedButton.icon(
                    onPressed: () => _toggleFavorite(spot),
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: AppColors.primary),
                    label: Text(fav ? '찜 해제' : '찜하기'),
                  );
                },
              ),
              FilledButton.icon(
                onPressed: () {
                  // 상세를 닫고 AI 플래너 탭으로 가서 입력창을 미리 채웁니다.
                  // popUntil(route.isFirst): 쌓인 화면을 첫 화면(탭 틀)까지 닫습니다. 그다음 AI 플래너 탭으로 이동하며 입력창을 미리 채웁니다.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  scope.shell.goPlanner(prefill: '${spot.title}을 포함한 일정');
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('이 장소로 일정 짜기'),
              ),
            ],
          ),
          if (_foods.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 20),
                const SizedBox(width: 8),
                Text('근처 추천 식당', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            for (final food in _foods)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 56, height: 56, child: SpotImage(spot: food.spot, height: 56, iconSize: 24)),
                  ),
                  title: Text(food.spot.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${food.spot.category} · ${distanceText(food.distanceKm)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => SpotDetailScreen.open(context, spotId: food.spot.id, initial: food.spot),
                ),
              ),
            const Text('직선 거리가 가까운 순서입니다. 사진은 그 식당이 아니라 같은 종류 음식의 예시 사진입니다.',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

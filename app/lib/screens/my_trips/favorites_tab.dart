// "내 여행 > 찜한 곳" 탭입니다. 찜 목록은 앱 전체가 함께 쓰는 FavoritesStore 가 들고 있어서, 이 파일은 그 값을 그리기만 합니다.
// 부모(my_trips_screen.dart)가 로그인했을 때만 이 탭을 보여 주므로 여기서는 로그인 여부를 따로 확인하지 않습니다.

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../app_scope.dart';
import '../../theme.dart';
import '../../widgets/load_more_footer.dart';
import '../../widgets/login_prompt.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/state_views.dart';
import '../spot_detail_screen.dart';

/// "내 여행 > 찜한 곳" 탭. 찜 목록은 앱 전체가 함께 쓰는 FavoritesStore 가 들고 있어서,
/// 상세 화면에서 하트를 누르면 이 탭도 바로 바뀝니다.
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // StatelessWidget 이지만 ListenableBuilder 로 favorites 의 변화를 들어서, 상세 화면에서 하트를 누르면 이 탭도 바로 바뀝니다.
    final favorites = AppScope.of(context).favorites;
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
        // 로딩 → 오류 → 비어 있음 → 목록 순서로 먼저 맞는 것을 보여 줍니다. 이미 목록이 있으면 새로 불러오는 중에도 목록을 그대로 둡니다.
        if (favorites.loading && favorites.items.isEmpty) return const LoadingView();
        if (favorites.error != null) return ErrorView(message: favorites.error!, onRetry: favorites.refresh);
        if (favorites.items.isEmpty) {
          return const EmptyView(message: '아직 찜한 곳이 없어요.\n마음에 드는 곳에서 하트를 눌러 보세요.', icon: Icons.favorite_border);
        }
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: SpotCard.height,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: favorites.items.length,
                itemBuilder: (context, i) {
                  final spot = favorites.items[i];
                  return SpotCard(
                    spot: spot,
                    onTap: () => SpotDetailScreen.open(context, spotId: spot.id, initial: spot),
                    corner: IconButton.filledTonal(
                      tooltip: '찜 해제',
                      icon: const Icon(Icons.favorite, color: AppColors.primary),
                      // toggle 은 서버에 요청하는 일이라 기다리고(await), 실패하면 서버 문구를 안내로 띄웁니다. 기다린 뒤에는 화면이 닫혔을 수 있어 context.mounted 를 확인합니다.
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
              ),
            ),
            SliverToBoxAdapter(
              child: LoadMoreFooter(
                hasMore: favorites.hasMore,
                loadingMore: favorites.loadingMore,
                onPressed: () async {
                  final message = await favorites.loadMore();
                  if (message != null && context.mounted) showSnack(context, message);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

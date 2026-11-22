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
    final favorites = AppScope.of(context).favorites;
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
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

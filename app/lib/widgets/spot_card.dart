import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../theme.dart';
import 'spot_image.dart';

/// 큰 사진 카드. 홈의 가로 목록과 탐색 그리드에서 함께 씁니다.
/// 높이는 부모가 정해 주므로(SizedBox 또는 그리드 mainAxisExtent) 글이 넘치면 줄입니다.
class SpotCard extends StatelessWidget {
  const SpotCard({super.key, required this.spot, required this.onTap});
  final Spot spot;
  final VoidCallback onTap;

  /// 카드 높이 권장값.
  static const double height = 290;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: SpotImage(spot: spot, height: 160),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        spot.oneLiner,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${spot.area} · ${spot.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 관광지 사진 위젯(SpotImage)과, 사진이 없을 때 대신 깔아 주는 그림(FallbackArt)입니다. 사진은 서버가 준 주소(imageUrl)에서 인터넷으로 받아 옵니다.

import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../theme.dart';

/// 관광지 사진. 사진이 없거나(null) 불러오기에 실패하면 [FallbackArt] 를 보여 줍니다.
class SpotImage extends StatelessWidget {
  const SpotImage({super.key, required this.spot, this.height, this.iconSize = 40});
  final Spot spot;
  final double? height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    // 사진이 없거나(null) 비어 있으면 곧바로 대체 그림을 돌려줍니다.
    final fallback = FallbackArt(spot: spot, height: height, iconSize: iconSize);
    final url = spot.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        // 사진을 받아 오는 동안에도 대체 그림을 깔아 두면 깜빡임이 적습니다.
        // Image.network 는 사진을 받는 동안(loadingBuilder)과 실패했을 때(errorBuilder) 무엇을 보일지 정할 수 있습니다. 둘 다 대체 그림을 보여 줍니다.
        loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}

/// 대체 그림: 테마에 따라 색이 다른 부드러운 그라데이션 + 가운데 작은 아이콘.
/// 바다 = 틸 계열, 오름·숲 = 초록 계열, 그 밖 = 오렌지·모래 계열 (docs/design.md).
class FallbackArt extends StatelessWidget {
  const FallbackArt({super.key, required this.spot, this.height, this.iconSize = 40});
  final Spot spot;
  final double? height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tags = spot.themeTags;
    // final 로 선언만 해 두고 아래 if / else 에서 한 번만 값을 넣습니다. 테마 태그에 따라 색과 아이콘이 달라집니다.
    final List<Color> colors;
    final IconData icon;
    if (tags.contains('바다')) {
      colors = const [Color(0xFFCCEFEA), Color(0xFF7CC8BF)];
      icon = Icons.waves;
    } else if (tags.contains('오름') || tags.contains('숲')) {
      colors = const [Color(0xFFDDEFD2), Color(0xFF9CCB8A)];
      icon = Icons.park;
    } else {
      colors = const [Color(0xFFFFE4CF), Color(0xFFF3D7B5)];
      icon = Icons.landscape;
    }
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Center(child: Icon(icon, size: iconSize, color: AppColors.ink.withValues(alpha: 0.35))),
    );
  }
}

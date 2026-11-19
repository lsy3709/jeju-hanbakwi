import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/spot.dart';
import '../theme.dart';

/// OpenStreetMap 지도(키 필요 없음). 핀을 누르면 이름과 "자세히" 링크가 뜹니다.
class SpotMap extends StatelessWidget {
  const SpotMap({super.key, required this.spots, this.onOpen, this.interactive = true, this.zoom});
  final List<Spot> spots;

  /// "자세히" 를 눌렀을 때. null 이면 핀을 눌러도 아무 일도 없습니다(상세 화면의 작은 지도).
  final void Function(Spot spot)? onOpen;
  final bool interactive;
  final double? zoom;

  // 제주도 한가운데쯤
  static const _jejuCenter = LatLng(33.38, 126.55);

  @override
  Widget build(BuildContext context) {
    final center = spots.isEmpty
        ? _jejuCenter
        : LatLng(
            spots.map((s) => s.lat).reduce((a, b) => a + b) / spots.length,
            spots.map((s) => s.lng).reduce((a, b) => a + b) / spots.length,
          );
    return FlutterMap(
      // 핀 목록이 바뀌면 지도를 새로 만들어 중심을 다시 잡습니다.
      key: ValueKey(spots.map((s) => s.id).join(',')),
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom ?? (spots.length == 1 ? 13 : 9.5),
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM 타일 서버는 앱을 알아볼 수 있는 이름을 요구합니다.
          userAgentPackageName: 'com.goldmagnet.jejuhanbakwi',
        ),
        MarkerLayer(
          markers: [
            for (final s in spots)
              Marker(
                point: LatLng(s.lat, s.lng),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onOpen == null ? null : () => _showSheet(context, s),
                  child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(source: Text('© OpenStreetMap contributors')),
      ],
    );
  }

  void _showSheet(BuildContext context, Spot spot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spot.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(spot.oneLiner, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onOpen!(spot);
                },
                child: const Text('자세히'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

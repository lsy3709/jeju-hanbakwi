// 관광지 위치를 지도에 핀으로 보여 주는 위젯입니다. 탐색 화면의 지도 보기와 상세 화면의 작은 지도가 같이 씁니다.
// 지도는 OpenStreetMap(무료, 키 불필요)을 flutter_map 패키지로 그립니다. 위도(lat)와 경도(lng)는 지구 위 위치를 나타내는 숫자 두 개입니다.

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
    // 위치가 없는 곳은 지도에 그릴 수 없으니 뺍니다.
    // this.spots 는 받은 전체 목록, spots 는 위치가 있는 것만 거른 새 목록입니다(이름이 같아서 this 로 구분).
    final spots = this.spots.where((s) => s.hasLocation).toList();
    // 핀이 있으면 위도 · 경도의 평균(대략 가운데)을, 없으면 제주 한가운데를 중심으로 잡습니다. s.lat! 의 ! 는 위에서 걸러서 null 이 아님이 확실하다는 뜻입니다.
    final center = spots.isEmpty
        ? _jejuCenter
        : LatLng(
            spots.map((s) => s.lat!).reduce((a, b) => a + b) / spots.length,
            spots.map((s) => s.lng!).reduce((a, b) => a + b) / spots.length,
          );
    return FlutterMap(
      // 핀 목록이 바뀌면 지도를 새로 만들어 중심을 다시 잡습니다.
      // key 가 바뀌면 Flutter 가 지도를 새로 만듭니다. 핀 목록이 바뀔 때 지도 중심도 다시 잡히게 하려는 것입니다.
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
                point: LatLng(s.lat!, s.lng!),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  // onOpen 이 없으면 핀을 눌러도 아무 일도 없습니다(null 이면 누르기 동작 자체가 없음).
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

  // 핀을 누르면 아래에서 올라오는 작은 창(bottom sheet)에 이름과 "자세히" 버튼을 보여 줍니다.
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

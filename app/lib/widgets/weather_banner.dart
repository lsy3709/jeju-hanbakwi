// 홈 화면 위쪽의 날씨 배너 위젯입니다. 서버가 준 한 줄 메시지와 지역별 오늘 날씨를 보여 주고, 비 오는 날에는 "실내 코스 보기" 버튼을 보입니다.
// weather 가 null 이면(날씨 서비스 실패) 안내 문구만 보여 줘서, 날씨가 안 와도 홈은 열립니다.

import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../theme.dart';

/// 홈의 날씨 배너: 서버가 준 한 줄 메시지 + 오늘 제주시·서귀포시 날씨.
/// [weather] 가 null 이면(날씨 서비스 실패) 안내 문구만 보여 줍니다.
class WeatherBanner extends StatelessWidget {
  const WeatherBanner({super.key, required this.weather, required this.onIndoor});
  final Weather? weather;

  /// 비 오는 날에만 보이는 "실내 코스 보기" 버튼.
  final VoidCallback onIndoor;

  // switch 식: 서버가 준 날씨 이름(sun, rain …)을 화면의 아이콘으로 바꿉니다. 마지막 _ 는 "그 밖의 모든 경우"입니다.
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
    // 필드 대신 지역 변수 w 에 한 번 담아 두면 아래에서 null 검사 뒤 w. 로 안전하게 쓸 수 있습니다.
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
                                // [ … ].join(' ') 은 목록의 글을 공백으로 이어 한 줄로 만듭니다. 목록 안 if 로 기온이 있을 때만 기온 조각을 넣습니다.
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

// 일정(여러 날)을 날마다 카드로, 칸마다 줄로 보여 주는 위젯입니다. AI 플래너 결과(plan_result_view)와 저장한 일정(trips_tab) 두 곳에서 같이 씁니다.
// 장소를 누르면 무엇을 할지는 이 위젯이 정하지 않고, 부모가 넘긴 onSpotTap 에 spotId 만 알려 줍니다.

import 'package:flutter/material.dart';

import '../format.dart';
import '../models/itinerary.dart';
import '../theme.dart';

/// 일자별 타임라인 카드. 장소를 누르면 [onSpotTap] 으로 spot_id 를 알려 줍니다.
class ItineraryView extends StatelessWidget {
  const ItineraryView({super.key, required this.days, required this.onSpotTap});
  final List<ItineraryDay> days;
  final void Function(int spotId) onSpotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // for 안의 ...[ ] 는 날마다 카드와 간격 위젯 둘을 목록 안에 펼쳐 넣는 문법입니다.
        for (final day in days) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      // "1일차 · 11월 20일 (금)" (웹과 같은 표기). 날짜가 없으면 "1일차"만, 날씨도 있을 때만 보여 줍니다.
                      Text(dayTitle(day.day, day.date), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      if (day.weather != null) _Pill(text: day.weather!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in day.items)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSpotTap(item.spotId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(item.time, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary)),
                                  if (item.reason.isNotEmpty)
                                    Text(item.reason, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// 날씨 같은 짧은 글을 알약에 담는 작은 위젯입니다. _ 로 시작해 이 파일 안에서만 씁니다.
class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

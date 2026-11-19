import 'package:flutter/material.dart';

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
                      Text('${day.day}일차', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      // 날짜·날씨는 null 일 수 있어서 있을 때만 보여 줍니다.
                      if (day.date != null) Text(day.date!, style: const TextStyle(color: AppColors.muted)),
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

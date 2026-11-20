import 'package:flutter/material.dart';

import '../models/itinerary.dart';
import '../theme.dart';
import 'itinerary_view.dart';

/// AI 플래너의 결과: ("간단 추천" 표시) → 설명 → 일자별 타임라인 → "내 여행에 저장" 버튼.
class PlanResultView extends StatelessWidget {
  const PlanResultView({super.key, required this.result, required this.onSpotTap, required this.onSave});
  final PlanResult result;
  final ValueChanged<int> onSpotTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 서버가 AI 대신 규칙으로 짠 결과라면 그렇다고 알려 줍니다.
        if (result.isSimple)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              '간단 추천',
              style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            ),
          ),
        if (result.answer.isNotEmpty) Text(result.answer, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 16),
        ItineraryView(days: result.itinerary, onSpotTap: onSpotTap),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('내 여행에 저장'),
        ),
      ],
    );
  }
}

// AI 플래너의 결과를 보여 주는 위젯입니다: (안내 글) → ("간단 추천" 표시) → 설명 → 일자별 타임라인 → 저장 버튼 또는 자동 저장 안내.
// planner_screen.dart 가 PlannerController.result 를 넘겨 주며, 버튼을 누르면 무엇을 할지는 onSave · onSpotTap 으로 부모가 정합니다.

import 'package:flutter/material.dart';

import '../models/itinerary.dart';
import '../theme.dart';
import 'itinerary_view.dart';

/// AI 플래너의 결과: ("간단 추천" 표시) → 설명 → 일자별 타임라인 → "내 여행에 저장" 버튼.
class PlanResultView extends StatelessWidget {
  const PlanResultView({
    super.key,
    required this.result,
    required this.onSpotTap,
    required this.onSave,
    this.onOpenSettings,
  });
  final PlanResult result;
  final ValueChanged<int> onSpotTap;
  final VoidCallback onSave;

  /// 안내 글(notice) 옆의 "설정 열기". null 이면 단추를 그리지 않습니다.
  // ? 가 붙은 함수는 없을 수도 있습니다(null 이면 "설정 열기" 버튼을 그리지 않음).
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 내 AI 키로 일정을 받지 못해 다른 방식으로 대신했을 때 서버가 보내는 안내.
        // 위젯 목록 안의 if 는 조건이 참일 때만 그 위젯을 넣습니다. result.notice! 의 ! 는 위에서 null 이 아님을 확인했다는 표시입니다.
        if (result.notice != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.notice!),
                if (onOpenSettings != null) TextButton(onPressed: onOpenSettings, child: const Text('설정 열기')),
              ],
            ),
          ),
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
        // 로그인한 채로 짠 일정은 서버가 바로 저장해 줍니다. 그때는 저장 단추 대신 안내만 보여 줍니다.
        // 로그인한 채 짠 일정은 서버가 이미 저장했으니 저장 버튼 대신 안내를 보여 주고, 아니면 저장 버튼(else)을 보여 줍니다.
        if (result.savedTrip != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bookmark_added_outlined, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '내 여행에 자동으로 저장했어요. 제목: ${result.savedTrip!.title}',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('내 여행에 저장'),
          ),
      ],
    );
  }
}

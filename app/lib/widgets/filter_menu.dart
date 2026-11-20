import 'package:flutter/material.dart';

import '../theme.dart';

/// "지역 ▾" 처럼 알약 모양으로 보이는 선택 메뉴. 고르면 라벨이 선택값으로 바뀝니다.
class FilterMenu extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> options;

  /// 고른 값. "전체"를 고르면 null (조건 해제).
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return PopupMenuButton<String>(
      tooltip: '$label 고르기',
      // 메뉴 항목의 값은 String 만 쓸 수 있어서, 빈 문자열을 "전체"(조건 해제)로 약속합니다.
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (context) => [
        PopupMenuItem(value: '', child: Text('$label 전체')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value ?? label, style: TextStyle(color: selected ? Colors.white : AppColors.ink)),
            Icon(Icons.arrow_drop_down, size: 20, color: selected ? Colors.white : AppColors.muted),
          ],
        ),
      ),
    );
  }
}

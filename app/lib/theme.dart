import 'package:flutter/material.dart';

/// 디자인 토큰(docs/design.md). 이 값 몇 개만 바꾸면 브랜드 색이 통째로 바뀝니다.
class AppColors {
  static const primary = Color(0xFFF26B1D); // 감귤 오렌지: 주요 버튼, 선택된 칩
  static const primaryDark = Color(0xFFD4560F); // 눌림
  static const secondary = Color(0xFF0F766E); // 바다 틸: 태그, 링크
  static const ink = Color(0xFF1F2430); // 본문 글자
  static const muted = Color(0xFF6B7280); // 보조 글자
  static const line = Color(0xFFE7E2DA); // 테두리
  static const sand = Color(0xFFFAF7F2); // 페이지 바탕
  static const surface = Color(0xFFFFFFFF); // 카드 바탕
}

class AppRadius {
  static const double card = 16;
  static const double pill = 999;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    outline: AppColors.line,
  );
  const pill = StadiumBorder();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.sand,
    // 글꼴은 앱에 함께 넣은 Pretendard 를 씁니다. (pubspec.yaml 의 fonts)
    fontFamily: 'Pretendard',
    // textTheme 은 따로 주지 않습니다. (기본 글자색은 위 colorScheme 의 onSurface 에서 옵니다)
    // Typography.xxx 를 넣으면 그 안의 Roboto 글꼴이 fontFamily 를 덮어써 한글 너비가 틀어집니다.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sand,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(pill),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed) ? AppColors.primaryDark : AppColors.primary,
        ),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(pill),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
        foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      // 칩 글자 스타일에는 글꼴과 크기를 꼭 함께 적습니다.
      // 색만 적으면 칩이 기본 글꼴로 너비를 재서, 웹 실행에서 한글이 잘려 보입니다.
      labelStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: AppColors.ink),
      secondaryLabelStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Colors.white),
      checkmarkColor: Colors.white,
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
    ),
  );
}

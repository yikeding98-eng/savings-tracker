import 'package:flutter/material.dart';

/// 金色主题的色板，集中在这里改一处就能全局生效
class GoldPalette {
  /// 主金色（FAB、开关、进度环）
  static const Color gold = Color(0xFFD4AF37);

  /// 深金：白底上的文字与图标，保证对比度
  static const Color goldDeep = Color(0xFF8A6A15);

  /// 卡片渐变的亮端
  static const Color goldLight = Color(0xFFF2D98A);

  /// 卡片渐变的中段
  static const Color goldMid = Color(0xFFC9A236);

  /// 金色底上的深色字
  static const Color ink = Color(0xFF3B2C00);

  /// 取出 / 还差 一类的辅助色（琥珀棕）
  static const Color copper = Color(0xFFB4682C);

  /// 浅色背景（暖象牙）
  static const Color surfaceWarm = Color(0xFFFBF7EC);

  static const Color surfaceDark = Color(0xFF141210);
  static const Color cardDark = Color(0xFF1F1B13);
  static const Color cardDarkAlt = Color(0xFF1A1710);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GoldPalette.gold,
    brightness: Brightness.light,
  ).copyWith(
    primary: GoldPalette.goldDeep,
    onPrimary: Colors.white,
    secondary: GoldPalette.copper,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GoldPalette.surfaceWarm,
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: GoldPalette.gold.withValues(alpha: 0.35),
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GoldPalette.goldDeep,
        foregroundColor: Colors.white,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GoldPalette.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFE6C766),
    onPrimary: const Color(0xFF2A2000),
    secondary: const Color(0xFFE09B63),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GoldPalette.surfaceDark,
    cardTheme: CardThemeData(
      elevation: 0,
      color: GoldPalette.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GoldPalette.cardDarkAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: GoldPalette.cardDarkAlt,
      indicatorColor: scheme.primary.withValues(alpha: 0.2),
      elevation: 0,
    ),
  );
}

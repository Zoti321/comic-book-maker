import 'package:flutter/material.dart';

/// 应用壳层侧栏 M3 色板（与 [AppTheme.light] 中性工具风一致）。
abstract final class AppSidebarTheme {
  static const width = 16.0 * 16; // 256px

  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF3F3F46);
  static const primary = Color(0xFF18181B);
  static const primaryForeground = Color(0xFFFAFAFA);
  static const accent = Color(0xFFF4F4F5);
  static const accentForeground = Color(0xFF18181B);
  static const border = Color(0xFFE4E4E7);
  /// 品牌/标题强调色（与主题 primary 一致）。
  static const brandAccent = Color(0xFF2563EB);

  static const menuButtonHeight = 36.0;
  static const menuButtonHeightLg = 48.0;
  static const menuButtonRadius = 8.0;
  static const groupLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: Color(0xFF71717A),
    letterSpacing: 0.02,
  );
}

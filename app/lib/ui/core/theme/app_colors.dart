import 'package:flutter/material.dart';

/// 中性灰阶色板（zinc 风格）；[AppTheme] 与 [AppSidebarTheme] 的唯一色值来源。
///
/// 本阶段无品牌强调色；交互层次靠表面色阶、字重与边框区分。仅 [error] 保留功能性红色。
abstract final class AppColors {
  static const background = Color(0xFFF4F4F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFFAFAFA);
  static const surfaceContainer = Color(0xFFF4F4F5);
  static const surfaceContainerHigh = Color(0xFFE4E4E7);
  static const surfaceContainerHighest = Color(0xFFD4D4D8);

  static const onSurface = Color(0xFF18181B);
  static const onSurfaceVariant = Color(0xFF71717A);
  static const outline = Color(0xFFE4E4E7);
  static const outlineVariant = Color(0xFFF4F4F5);

  /// 主操作色：深灰填充（非品牌色）。
  static const primary = Color(0xFF27272A);
  static const onPrimary = Color(0xFFFAFAFA);
  static const primaryContainer = Color(0xFFF4F4F5);
  static const onPrimaryContainer = Color(0xFF18181B);

  static const secondary = Color(0xFF52525B);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFF4F4F5);
  static const onSecondaryContainer = Color(0xFF3F3F46);

  static const tertiary = Color(0xFF71717A);
  static const onTertiary = Color(0xFFFFFFFF);

  static const error = Color(0xFFDC2626);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onErrorContainer = Color(0xFF991B1B);

  static const inverseSurface = Color(0xFF27272A);
  static const onInverseSurface = Color(0xFFFAFAFA);
  static const inversePrimary = Color(0xFFA1A1AA);

  static const shadow = Color(0x1A000000);
  static const scrim = Color(0x66000000);
}

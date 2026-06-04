import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 应用 UI 字体：使用各平台系统字体，避免运行时从 Google Fonts CDN 下载。
abstract final class AppFonts {
  static const fallback = <String>[
    'Microsoft YaHei',
    'Microsoft YaHei UI',
    'PingFang SC',
    'Noto Sans CJK SC',
    'Segoe UI',
    'sans-serif',
  ];

  /// 各平台优先使用的系统字体（无网络、无 google_fonts 下载）。
  static String? get primary {
    if (kIsWeb) return null;
    if (Platform.isWindows) return 'Microsoft YaHei UI';
    if (Platform.isMacOS || Platform.isIOS) return 'PingFang SC';
    if (Platform.isLinux) return 'Noto Sans CJK SC';
    return null;
  }

  static TextTheme applyTo(ColorScheme scheme, TextTheme base) {
    return base.apply(
      fontFamily: primary,
      fontFamilyFallback: fallback,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }

  static TextStyle textStyle({
    required ColorScheme scheme,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: primary,
      fontFamilyFallback: fallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? scheme.onSurface,
    );
  }
}

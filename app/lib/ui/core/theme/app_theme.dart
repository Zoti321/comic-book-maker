import 'package:comic_book_maker/ui/core/theme/app_fonts.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';

import 'package:flutter/material.dart';

export 'app_colors.dart';
export 'app_tokens.dart';

/// Material You 主题（蓝色 seed）与 design token。
abstract final class AppTheme {
  /// M3 蓝色 seed，用于 [ColorScheme.fromSeed] 生成浅色与深色配色。
  static const seedColor = Color(0xFF1565C0);

  static const _radius = AppRadius.lg;

  /// M3 浅色 [ThemeData]（应用根主题）。
  static ThemeData light() => _theme(Brightness.light);

  /// M3 深色 [ThemeData]。
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(surfaceTint: Colors.transparent);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.compact,
    );

    final themed = base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppFonts.textStyle(
          scheme: scheme,
          fontSize: AppTypography.titleLargeSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: scheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: TextStyle(
          fontSize: AppTypography.bodySize,
          color: scheme.onSurfaceVariant,
          fontFamily: AppFonts.primary,
          fontFamilyFallback: AppFonts.fallback,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppFonts.textStyle(
            scheme: scheme,
            fontSize: AppTypography.labelSize,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: AppDurations.tooltipWait,
      ),
    );

    return themed.copyWith(
      textTheme: AppFonts.applyTo(scheme, themed.textTheme),
      primaryTextTheme: AppFonts.applyTo(scheme, themed.primaryTextTheme),
    );
  }
}

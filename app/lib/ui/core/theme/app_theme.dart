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
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 56,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 56,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outline),
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
        indicatorShape: const StadiumBorder(),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.surfaceContainerHighest;
          }
          return null;
        }),
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
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(
          color: scheme.onSecondaryContainer,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelTextStyle: AppFonts.textStyle(
          scheme: scheme,
          fontSize: AppTypography.labelSize,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: AppFonts.textStyle(
          scheme: scheme,
          fontSize: AppTypography.labelSize,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
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
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: scheme.outline),
            ),
          ),
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

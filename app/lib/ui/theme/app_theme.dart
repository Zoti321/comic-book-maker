import 'package:comic_book_maker/ui/theme/app_fonts.dart';

import 'package:comic_book_maker/ui/theme/app_tokens.dart';

import 'package:flutter/material.dart';

export 'app_tokens.dart';

/// Material 3 浅色主题与 design token。

abstract final class AppTheme {

  static const _radius = AppRadius.lg;



  // --- 专业工具风中性色 + 克制蓝色强调 ---

  static const _background = Color(0xFFF4F4F5);

  static const _surface = Color(0xFFFFFFFF);

  static const _onSurface = Color(0xFF18181B);

  static const _onSurfaceVariant = Color(0xFF71717A);

  static const _outline = Color(0xFFE4E4E7);

  static const _primary = Color(0xFF2563EB);

  static const _onPrimary = Color(0xFFFFFFFF);

  static const _secondaryContainer = Color(0xFFF4F4F5);

  static const _onSecondaryContainer = Color(0xFF3F3F46);

  static const _error = Color(0xFFDC2626);



  /// M3 浅色 [ThemeData]（应用根主题）。

  static ThemeData light() {

    const scheme = ColorScheme(

      brightness: Brightness.light,

      primary: _primary,

      onPrimary: _onPrimary,

      primaryContainer: Color(0xFFDBEAFE),

      onPrimaryContainer: Color(0xFF1E3A8A),

      secondary: Color(0xFF52525B),

      onSecondary: Color(0xFFFFFFFF),

      secondaryContainer: _secondaryContainer,

      onSecondaryContainer: _onSecondaryContainer,

      tertiary: Color(0xFF64748B),

      onTertiary: Color(0xFFFFFFFF),

      error: _error,

      onError: Color(0xFFFFFFFF),

      surface: _surface,

      onSurface: _onSurface,

      onSurfaceVariant: _onSurfaceVariant,

      outline: _outline,

      outlineVariant: Color(0xFFF4F4F5),

      shadow: Color(0x1A000000),

      scrim: Color(0x66000000),

      inverseSurface: Color(0xFF27272A),

      onInverseSurface: Color(0xFFFAFAFA),

      inversePrimary: Color(0xFF93C5FD),

      surfaceTint: _primary,

    );



    final base = ThemeData(

      useMaterial3: true,

      brightness: Brightness.light,

      colorScheme: scheme,

      scaffoldBackgroundColor: _background,

      visualDensity: VisualDensity.compact,

    );



    final themed = base.copyWith(

      appBarTheme: AppBarTheme(

        centerTitle: false,

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: _surface,

        foregroundColor: _onSurface,

        surfaceTintColor: Colors.transparent,

        titleTextStyle: AppFonts.textStyle(

          scheme: scheme,

          fontSize: AppTypography.titleLargeSize,

          fontWeight: FontWeight.w600,

        ),

      ),

      cardTheme: CardThemeData(

        elevation: 0,

        color: _surface,

        surfaceTintColor: Colors.transparent,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(_radius),

          side: const BorderSide(color: _outline),

        ),

        margin: EdgeInsets.zero,

      ),

      filledButtonTheme: FilledButtonThemeData(

        style: FilledButton.styleFrom(

          minimumSize: const Size(64, AppTypography.controlHeight),

          padding: const EdgeInsets.symmetric(horizontal: 16),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(AppRadius.md),

          ),

        ),

      ),

      outlinedButtonTheme: OutlinedButtonThemeData(

        style: OutlinedButton.styleFrom(

          minimumSize: const Size(64, AppTypography.controlHeight),

          padding: const EdgeInsets.symmetric(horizontal: 16),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(AppRadius.md),

          ),

        ),

      ),

      textButtonTheme: TextButtonThemeData(

        style: TextButton.styleFrom(

          minimumSize: const Size(48, AppTypography.controlHeight),

          padding: const EdgeInsets.symmetric(horizontal: 12),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(AppRadius.md),

          ),

        ),

      ),

      iconButtonTheme: IconButtonThemeData(

        style: IconButton.styleFrom(

          visualDensity: VisualDensity.compact,

        ),

      ),

      inputDecorationTheme: InputDecorationTheme(

        filled: true,

        fillColor: const Color(0xFFFAFAFA),

        isDense: true,

        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: BorderSide.none,

        ),

        enabledBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: const BorderSide(color: _outline),

        ),

        focusedBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: const BorderSide(color: _primary, width: 1.5),

        ),

        errorBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: const BorderSide(color: _error),

        ),

        labelStyle: TextStyle(

          fontSize: AppTypography.bodySize,

          color: _onSurfaceVariant,

          fontFamily: AppFonts.primary,

          fontFamilyFallback: AppFonts.fallback,

        ),

      ),

      navigationBarTheme: NavigationBarThemeData(

        elevation: 0,

        backgroundColor: _surface,

        indicatorColor: scheme.primaryContainer,

        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        labelTextStyle: WidgetStateProperty.resolveWith((states) {

          final selected = states.contains(WidgetState.selected);

          return AppFonts.textStyle(

            scheme: scheme,

            fontSize: AppTypography.labelSize,

            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,

            color: selected ? _onSurface : _onSurfaceVariant,

          );

        }),

      ),

      segmentedButtonTheme: SegmentedButtonThemeData(

        style: ButtonStyle(

          visualDensity: VisualDensity.compact,

          padding: WidgetStateProperty.all(

            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

          ),

        ),

      ),

      dividerTheme: const DividerThemeData(

        color: _outline,

        space: 1,

        thickness: 1,

      ),

      snackBarTheme: SnackBarThemeData(

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(AppRadius.md),

        ),

      ),

      dialogTheme: DialogThemeData(

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(AppRadius.lg),

        ),

      ),

    );



    return themed.copyWith(

      textTheme: AppFonts.applyTo(scheme, themed.textTheme),

      primaryTextTheme: AppFonts.applyTo(scheme, themed.primaryTextTheme),

    );
  }
}


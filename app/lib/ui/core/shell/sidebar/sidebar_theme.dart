import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';

/// 应用壳层侧栏布局常量（色值统一走 [ThemeData.colorScheme]）。
abstract final class AppSidebarTheme {
  static const width = AppLayout.sidebarWidth;

  static const menuButtonHeight = AppTypography.controlHeight;
  static const menuButtonHeightLg = 48.0;
  static const menuButtonRadius = AppRadius.md;
}

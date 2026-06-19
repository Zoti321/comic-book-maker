import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme uses blue seed for light and dark ColorScheme', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(AppTheme.seedColor, const Color(0xFF1565C0));
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);

    // Material You blue primary — not legacy zinc gray.
    expect(light.colorScheme.primary.value & 0xFFFFFF, isNot(0x27272A));
    expect(dark.colorScheme.primary.value & 0xFFFFFF, isNot(0x27272A));
    expect(light.colorScheme.primary.blue, greaterThan(light.colorScheme.primary.red));
    expect(dark.colorScheme.primary.blue, greaterThan(dark.colorScheme.primary.red));

    expect(light.colorScheme.surfaceTint, Colors.transparent);
    expect(dark.colorScheme.surfaceTint, Colors.transparent);
  });

  test('design tokens use tightened sm radius', () {
    expect(AppRadius.sm, 4.0);
    expect(AppRadius.md, 8.0);
  });

  test('AppTheme uses InkSparkle splash factory', () {
    expect(AppTheme.light().splashFactory, InkSparkle.splashFactory);
    expect(AppTheme.dark().splashFactory, InkSparkle.splashFactory);
  });

  test('AppTheme.light sets global tooltip wait duration', () {
    final theme = AppTheme.light();

    expect(theme.tooltipTheme.waitDuration, AppDurations.tooltipWait);
    expect(AppDurations.tooltipWait, const Duration(seconds: 1));
  });
}

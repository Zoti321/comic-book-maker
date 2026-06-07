import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme.light uses neutral palette without brand accent', () {
    final theme = AppTheme.light();
    final scheme = theme.colorScheme;

    expect(scheme.primary, AppColors.primary);
    expect(scheme.primary, const Color(0xFF27272A));
    expect(scheme.surfaceTint, Colors.transparent);
    expect(scheme.error, AppColors.error);
    expect(scheme.inversePrimary, AppColors.inversePrimary);

    // No blue brand tones in semantic colors.
    expect(scheme.primary.value & 0xFFFFFF, isNot(0x2563EB));
    expect(scheme.primaryContainer.value & 0xFFFFFF, isNot(0xDBEAFE));
    expect(scheme.inversePrimary.value & 0xFFFFFF, isNot(0x93C5FD));
  });

  test('filled button style follows neutral primary', () {
    final theme = AppTheme.light();
    final style = theme.filledButtonTheme.style!;

    expect(style.backgroundColor?.resolve({}), AppColors.primary);
    expect(style.foregroundColor?.resolve({}), AppColors.onPrimary);
  });
}

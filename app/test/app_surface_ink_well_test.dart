import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/app_surface_ink_well.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('libraryCard uses NoSplash with hover and press overlays', (
    tester,
  ) async {
    late ColorScheme scheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return Scaffold(
              body: Material(
                child: AppSurfaceInkWell(
                  preset: AppSurfaceInkPreset.libraryCard,
                  onTap: () {},
                  child: const SizedBox(height: 48, width: 48),
                ),
              ),
            );
          },
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.splashFactory, equals(NoSplash.splashFactory));

    final overlay = inkWell.overlayColor!;
    expect(
      overlay.resolve({WidgetState.pressed}),
      scheme.onSurface.withValues(alpha: 0.12),
    );
    expect(
      overlay.resolve({WidgetState.hovered}),
      scheme.onSurface.withValues(alpha: 0.08),
    );
    expect(overlay.resolve({WidgetState.focused}), isNull);
  });

  testWidgets('gridTile uses NoSplash with press-only overlay', (
    tester,
  ) async {
    late ColorScheme scheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return Scaffold(
              body: Material(
                child: AppSurfaceInkWell(
                  preset: AppSurfaceInkPreset.gridTile,
                  onTap: () {},
                  child: const SizedBox(height: 48, width: 48),
                ),
              ),
            );
          },
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.splashFactory, equals(NoSplash.splashFactory));

    final overlay = inkWell.overlayColor!;
    expect(
      overlay.resolve({WidgetState.pressed}),
      scheme.onSurface.withValues(alpha: 0.08),
    );
    expect(overlay.resolve({WidgetState.hovered}), isNull);
  });
}

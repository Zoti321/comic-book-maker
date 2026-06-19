import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showAppOverlayDialog', () {
    testWidgets('uses scale and fade transitions when motion enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const _DialogHost(),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pump();

      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);

      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text('测试内容'), findsOneWidget);
    });

    testWidgets('skips scale and fade when animations disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const _DialogHost(),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pump();

      expect(find.text('测试内容'), findsOneWidget);
    });
  });

  group('showAppBottomSheet', () {
    testWidgets('uses bottom-aligned scale and fade when motion enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const _SheetHost(),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pump();

      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);

      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text('Sheet 内容'), findsOneWidget);
    });

    testWidgets('skips transitions when animations disabled', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const _SheetHost(),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pump();

      expect(find.text('Sheet 内容'), findsOneWidget);
    });
  });
}

class _DialogHost extends StatelessWidget {
  const _DialogHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showAppOverlayDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              content: const Text('测试内容'),
            ),
          ),
          child: const Text('打开'),
        ),
      ),
    );
  }
}

class _SheetHost extends StatelessWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showAppBottomSheet<void>(
            context: context,
            builder: (sheetContext) => const Text('Sheet 内容'),
          ),
          child: const Text('打开'),
        ),
      ),
    );
  }
}

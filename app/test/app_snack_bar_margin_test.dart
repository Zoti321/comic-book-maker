import 'package:comic_book_maker/ui/core/feedback/app_snack_bar.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('appSnackBarMarginFor compact uses horizontal inset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final margin = appSnackBarMarginFor(context);
              expect(margin.left, AppSpacing.md);
              expect(margin.right, AppSpacing.md);
              expect(margin.bottom, AppSpacing.md);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('appSnackBarMarginFor medium+ anchors trailing corner', (
    WidgetTester tester,
  ) async {
    const viewportWidth = 1200.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(viewportWidth, 900)),
          child: Builder(
            builder: (context) {
              final margin = appSnackBarMarginFor(context);
              expect(margin.right, AppSpacing.lg);
              expect(margin.bottom, AppSpacing.lg);
              expect(
                margin.left,
                viewportWidth - kAppSnackBarMaxWidth - AppSpacing.lg,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}

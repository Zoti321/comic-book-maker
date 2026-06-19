import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('staggerEntrance wraps Animate when play is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: const SizedBox(
                width: 48,
                height: 48,
                child: Placeholder(),
              ).staggerEntrance(
                context,
                index: 1,
                play: true,
              ),
            );
          },
        ),
      ),
    );

    expect(find.byType(Animate), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  });

  testWidgets('staggerEntrance skips Animate when play is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: const SizedBox(
                width: 48,
                height: 48,
                child: Placeholder(),
              ).staggerEntrance(
                context,
                index: 0,
                play: false,
              ),
            );
          },
        ),
      ),
    );

    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('staggerEntrance skips Animate when motion disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Placeholder(),
                ).staggerEntrance(
                  context,
                  index: 0,
                  play: true,
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(Animate), findsNothing);
  });
}

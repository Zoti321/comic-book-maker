import 'package:comic_book_maker/ui/core/router/app_page_transitions.dart';
import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('fadeTransitionPage uses page transition tokens', (tester) async {
    late CustomTransitionPage<void> page;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            page = fadeTransitionPage<void>(
              context: context,
              key: const ValueKey<String>('editor'),
              child: const SizedBox(),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(page, isA<CustomTransitionPage<void>>());
    expect(page.transitionDuration, AppDurations.pageTransition);
    expect(AppPageTransitions.fadeDuration, AppDurations.pageTransition);
    expect(AppPageTransitions.fadeCurve, AppCurves.standard);
  });

  testWidgets('fadeTransitionPage uses zero duration when animations disabled', (
    tester,
  ) async {
    late CustomTransitionPage<void> page;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              page = fadeTransitionPage<void>(
                context: context,
                key: const ValueKey<String>('editor'),
                child: const SizedBox(),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(page.transitionDuration, Duration.zero);
    expect(page.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('AppMotion.duration respects disableAnimations', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(
                AppMotion.duration(context, AppDurations.motionNormal),
                Duration.zero,
              );
              expect(AppMotion.enabled(context), isFalse);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}

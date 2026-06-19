import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/library/library_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses animated title and fade entrance when motion enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LibraryEmptyState(onCreateProject: () {}),
        ),
      ),
    );

    expect(find.byType(AnimatedTextKit), findsOneWidget);
    expect(find.byType(Animate), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(AnimatedTextKit), findsOneWidget);
  });

  testWidgets('uses static title when animations disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: LibraryEmptyState(onCreateProject: () {}),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedTextKit), findsNothing);
    expect(find.byType(Animate), findsNothing);
    expect(find.text('还没有项目'), findsOneWidget);
  });
}

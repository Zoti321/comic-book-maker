import 'package:comic_book_maker/ui/core/router/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('fadeTransitionPage builds CustomTransitionPage with fade timing tokens', () {
    final page = fadeTransitionPage<void>(
      key: const ValueKey<String>('editor'),
      child: const SizedBox(),
    );

    expect(page, isA<CustomTransitionPage<void>>());
    expect(AppPageTransitions.fadeDuration.inMilliseconds, 200);
    expect(AppPageTransitions.fadeCurve, Curves.easeInOut);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 点击第一个 `onPressed` 非空的「创建」按钮。
Future<void> tapEnabledCreateButton(WidgetTester tester) async {
  final candidates = find.widgetWithText(FilledButton, '创建');
  expect(candidates, findsWidgets);

  for (final element in candidates.evaluate()) {
    final finder = find.byWidget(element.widget);
    final button = tester.widget<FilledButton>(finder);
    if (button.onPressed != null) {
      await tester.tap(finder);
      return;
    }
  }

  fail('No enabled 创建 FilledButton found');
}

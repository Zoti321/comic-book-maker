import 'package:comic_book_maker/ui/core/design_system/app_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not use InkWell and toggles when label is tapped', (
    WidgetTester tester,
  ) async {
    var checked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCheckbox(
            value: checked,
            onChanged: (value) => checked = value ?? false,
            label: '沿用应用默认导出目录',
            sublabel: '副标题',
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsNothing);

    await tester.tap(find.text('沿用应用默认导出目录'));
    await tester.pump();
    expect(checked, isTrue);
  });

  testWidgets('disabled checkbox does not toggle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCheckbox(
            value: false,
            onChanged: null,
            label: '只读选项',
          ),
        ),
      ),
    );

    await tester.tap(find.text('只读选项'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });
}

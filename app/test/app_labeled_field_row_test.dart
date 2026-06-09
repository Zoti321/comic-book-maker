import 'package:comic_book_maker/ui/core/design_system/app_labeled_field_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stacks label above field when width is below breakpoint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: AppLabeledFieldRow(
              label: '导出格式',
              child: Text('field'),
            ),
          ),
        ),
      ),
    );

    final labelFinder = find.text('导出格式');
    final fieldFinder = find.text('field');
    expect(labelFinder, findsOneWidget);
    expect(fieldFinder, findsOneWidget);
    expect(
      tester.getTopLeft(fieldFinder).dy,
      greaterThan(tester.getTopLeft(labelFinder).dy),
    );
  });

  testWidgets('places label left of field when width is wide enough', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: AppLabeledFieldRow(
              label: '导出格式',
              child: Text('field'),
            ),
          ),
        ),
      ),
    );

    final labelFinder = find.text('导出格式');
    final fieldFinder = find.text('field');
    expect(
      tester.getTopLeft(fieldFinder).dx,
      greaterThan(tester.getTopLeft(labelFinder).dx),
    );
  });
}

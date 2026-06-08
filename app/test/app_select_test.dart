import 'package:comic_book_maker/ui/core/design_system/app_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows label, selected value and helper', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSelect<String>(
            label: '格式',
            helper: '选择导出格式',
            value: 'a',
            onChanged: (_) {},
            items: const [
              AppSelectItem(value: 'a', label: '选项 A'),
              AppSelectItem(value: 'b', label: '选项 B'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('格式'), findsOneWidget);
    expect(find.text('选项 A'), findsOneWidget);
    expect(find.text('选择导出格式'), findsOneWidget);
  });
}

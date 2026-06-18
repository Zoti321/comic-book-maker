import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/app_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows label and selected value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppDropdownMenu<String>(
            label: '格式',
            value: 'a',
            onChanged: (_) {},
            items: const [
              AppDropdownMenuItem(value: 'a', label: '选项 A'),
              AppDropdownMenuItem(value: 'b', label: '选项 B'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('格式'), findsWidgets);
    expect(find.text('选项 A'), findsWidgets);
  });

  testWidgets('form fields use M3 56px height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              TextFormField(
                key: const Key('text'),
                decoration: const InputDecoration(labelText: '标签'),
                initialValue: '内容',
              ),
              AppDropdownMenu<String>(
                key: const Key('dropdown'),
                label: '标签',
                value: '选项',
                items: const [
                  AppDropdownMenuItem(value: '选项', label: '选项'),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('text'))).height,
      AppTypography.controlHeightForm,
    );
    expect(
      tester.getSize(find.byKey(const Key('dropdown'))).height,
      AppTypography.controlHeightForm,
    );
  });

  testWidgets('selects item from clearable menu', (tester) async {
    String? value = 'Everyone';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppDropdownMenu<String>(
                label: '年龄分级',
                value: value,
                clearable: true,
                items: const [
                  AppDropdownMenuItem(value: 'Everyone', label: 'Everyone'),
                  AppDropdownMenuItem(value: 'R18+', label: 'R18+'),
                ],
                onChanged: (next) => setState(() => value = next),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(DropdownMenu<String>),
            matching: find.byIcon(Icons.arrow_drop_down),
          )
          .last,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(
        of: find.text('R18+').last,
        matching: find.byType(MenuItemButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(value, 'R18+');
  });

  testWidgets('clearable shows clear button inside suffix', (tester) async {
    String? value = 'a';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppDropdownMenu<String>(
                label: '格式',
                value: value,
                clearable: true,
                onChanged: (next) => setState(() => value = next),
                items: const [
                  AppDropdownMenuItem(value: 'a', label: '选项 A'),
                  AppDropdownMenuItem(value: 'b', label: '选项 B'),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('清空'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DropdownMenu<String>),
        matching: find.byTooltip('清空'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('清空'));
    await tester.pumpAndSettle();

    expect(value, isNull);
    expect(find.byTooltip('清空'), findsNothing);
  });
}

import 'package:comic_book_maker/ui/core/design_system/app_text_field.dart';
import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    required Widget field,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: field),
      ),
    );
  }

  testWidgets('shows label, hint, and helper', (tester) async {
    await pumpField(
      tester,
      field: const AppTextField(
        label: '项目名称',
        hint: '留空则使用默认标题',
        helper: '将写入项目库显示名称',
      ),
    );

    expect(find.text('项目名称'), findsOneWidget);
    expect(find.text('留空则使用默认标题'), findsOneWidget);
    expect(find.text('将写入项目库显示名称'), findsOneWidget);
  });

  testWidgets('shows error text instead of helper', (tester) async {
    await pumpField(
      tester,
      field: const AppTextField(
        label: '项目名称',
        helper: '辅助说明',
        errorText: '名称不能为空',
      ),
    );

    expect(find.text('名称不能为空'), findsOneWidget);
    expect(find.text('辅助说明'), findsNothing);
  });

  testWidgets('calls onChanged when typing', (tester) async {
    final changes = <String>[];

    await pumpField(
      tester,
      field: AppTextField(
        label: '项目名称',
        onChanged: changes.add,
      ),
    );

    await tester.enterText(find.byType(TextField), '我的漫画');
    await tester.pump();

    expect(changes, ['我的漫画']);
  });

  testWidgets('does not accept input when disabled', (tester) async {
    final changes = <String>[];

    await pumpField(
      tester,
      field: AppTextField(
        enabled: false,
        onChanged: changes.add,
      ),
    );

    await tester.enterText(find.byType(TextField), 'test');
    await tester.pump();

    expect(changes, isEmpty);
  });

  testWidgets('shows error border when errorText is set', (tester) async {
    await pumpField(
      tester,
      field: const AppTextField(
        label: '项目名称',
        errorText: '名称不能为空',
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final border = container.decoration! as BoxDecoration;
    expect((border.border as Border).top.color, AppColors.error);
  });
}

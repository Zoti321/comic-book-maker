import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/app_field_suffix_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses 36px circular IconButton with 20px icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppFieldSuffixIconButton(
            tooltip: '清空',
            icon: Icons.close,
            onPressed: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    final style = button.style!;
    expect(style.fixedSize?.resolve({}), const Size(36, 36));
    expect(style.shape?.resolve({}), isA<CircleBorder>());
    expect(style.iconSize?.resolve({}), 20);
    expect(find.byTooltip('清空'), findsOneWidget);
  });
}

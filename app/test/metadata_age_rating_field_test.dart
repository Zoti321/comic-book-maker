import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/app_dropdown_menu.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_age_rating_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const presets = ['Adults Only 18+', 'Everyone', 'R18+', 'Unknown'];

  testWidgets('dropdown uses parent width and M3 form height', (tester) async {
    final controller = TextEditingController(text: 'Everyone');

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 320,
              child: MetadataAgeRatingField(
                label: '年龄分级',
                controller: controller,
                presets: presets,
                onChanged: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final menuBox = tester.renderObject<RenderBox>(
      find.byType(DropdownMenu<String>),
    );
    expect(menuBox.size.width, 320);
    expect(menuBox.size.height, AppTypography.controlHeightForm);

    await tester.tap(
      find
          .descendant(
            of: find.byType(DropdownMenu<String>),
            matching: find.byIcon(Icons.arrow_drop_down),
          )
          .last,
    );
    await tester.pumpAndSettle();

    final menuPanel = tester.renderObject<RenderBox>(
      find.byType(MenuAnchor),
    );
    expect(menuPanel.size.width, closeTo(320, 1));
  });

  testWidgets('selection triggers onChanged', (tester) async {
    var changed = 0;
    final controller = TextEditingController(text: 'Everyone');

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MetadataAgeRatingField(
            label: '年龄分级',
            controller: controller,
            presets: presets,
            onChanged: () => changed++,
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

    expect(changed, 1);
    expect(controller.text, 'R18+');
  });

  testWidgets('clear button sits inside dropdown suffix', (tester) async {
    final controller = TextEditingController(text: 'Everyone');

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MetadataAgeRatingField(
            label: '年龄分级',
            controller: controller,
            presets: presets,
            onChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppDropdownMenu<String>), findsOneWidget);
    expect(find.byType(DropdownMenu<String>), findsOneWidget);
    expect(find.byTooltip('清空'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DropdownMenu<String>),
        matching: find.byTooltip('清空'),
      ),
      findsOneWidget,
    );
  });
}

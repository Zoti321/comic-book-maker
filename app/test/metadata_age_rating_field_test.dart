import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_age_rating_field.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const presets = ['Adults Only 18+', 'Everyone', 'R18+', 'Unknown'];

  testWidgets('dropdown trigger uses available width beside clear button', (
    tester,
  ) async {
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

    final decoratorBox = tester.renderObject<RenderBox>(
      find.byType(InputDecorator),
    );
    expect(decoratorBox.size.width, greaterThan(240));

    await tester.tap(find.text('Everyone'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Adults Only 18+'), findsOneWidget);
    final menuItemBox = tester.renderObject<RenderBox>(
      find.text('Adults Only 18+'),
    );
    expect(menuItemBox.size.width, greaterThan(120));
  });

  testWidgets('clear button sits outside dropdown decoration', (tester) async {
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

    expect(find.byType(DropdownButtonFormField2<String>), findsOneWidget);
    expect(find.byTooltip('清空'), findsOneWidget);
  });
}

import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_comma_tags_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCommaSeparatedTags trims and dedupes case-insensitively', () {
    expect(
      parseCommaSeparatedTags('  foo , bar,FOO , ,baz '),
      ['foo', 'bar', 'baz'],
    );
  });

  test('formatCommaSeparatedTags uses comma without trailing spaces', () {
    expect(formatCommaSeparatedTags(['肉便器', '群交']), '肉便器,群交');
  });

  testWidgets('committing duplicate tag does not duplicate chips or text', (
    tester,
  ) async {
    final committed = TextEditingController(text: 'alpha');
    final focusNode = FocusNode();
    addTearDown(committed.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MetadataCommaTagsField(
            controller: committed,
            focusNode: focusNode,
            label: '标签（逗号分隔）',
            onChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('alpha'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(committed.text, 'alpha');
    expect(find.text('alpha'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'beta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(committed.text, 'alpha,beta');
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('autosave sync does not overwrite while input is focused', (
    tester,
  ) async {
    final committed = TextEditingController(text: 'seed');
    final focusNode = FocusNode();
    addTearDown(committed.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MetadataCommaTagsField(
            controller: committed,
            focusNode: focusNode,
            label: '标签（逗号分隔）',
            onChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'gamma');

    committed.text = 'seed,overwritten';
    await tester.pump();

    expect(find.text('gamma'), findsOneWidget);
    expect(find.text('overwritten'), findsNothing);
  });
}

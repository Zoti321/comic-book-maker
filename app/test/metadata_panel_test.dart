import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_panel.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui/features/project_editor/metadata_panel_harness.dart';
import 'support/data/repositories/in_memory_core_gateway.dart';

Finder numberTextField() => find.byType(TextFormField).at(1);

Future<void> selectSeriesSection(WidgetTester tester) async {
  await selectMetadataSection(tester, '系列');
}

Future<void> selectMetadataSection(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder publishingYearField() => find.byType(TextFormField).at(1);
Finder publishingMonthField() => find.byType(TextFormField).at(2);
Finder publishingDayField() => find.byType(TextFormField).at(3);

void main() {
  late InMemoryCoreGateway gateway;

  setUp(() {
    gateway = InMemoryCoreGateway.metadataPanel();
    gateway.metadataByProjectId['p1'] = kMetadataPanelFixture;
    gateway.metadataUpdateCallCount = 0;
    gateway.nextMetadataUpdateError = null;
    gateway.failMetadataUpdates = false;
    gateway.onMetadataUpdate = null;
  });

  testWidgets('shows canonical metadata fields regardless of export format', (
    tester,
  ) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );

    expect(find.text('元数据'), findsWidgets);
    expect(find.text('标题'), findsOneWidget);
    await selectMetadataSection(tester, '系列');
    expect(find.text('期号'), findsOneWidget);
    expect(find.text('ComicInfo'), findsNothing);
    expect(find.text('OPF Metadata'), findsNothing);
    expect(find.text('导出元数据'), findsNothing);
  });

  testWidgets('epub export format uses the same canonical schema', (
    tester,
  ) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.epub,
    );

    expect(find.text('元数据'), findsWidgets);
    expect(find.text('标题'), findsOneWidget);
    await selectMetadataSection(tester, '系列');
    expect(find.text('期号'), findsOneWidget);
    expect(find.text('OPF Metadata'), findsNothing);
    expect(find.text('固定版式'), findsNothing);
  });

  testWidgets('pdf export format uses the same canonical schema', (
    tester,
  ) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.pdf,
    );

    expect(find.text('元数据'), findsWidgets);
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('当前格式不支持编辑'), findsNothing);
  });

  testWidgets('published date year-only round trip', (tester) async {
    gateway.metadataByProjectId['p1'] = kMetadataPanelFixture.copyWith(
      publishedDate: '2024',
    );

    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );
    await selectMetadataSection(tester, '常规');

    expect(
      tester.widget<TextFormField>(publishingYearField()).controller?.text,
      '2024',
    );
    expect(
      tester.widget<TextFormField>(publishingMonthField()).controller?.text,
      '',
    );
    expect(
      tester.widget<TextFormField>(publishingDayField()).controller?.text,
      '',
    );

    await tester.enterText(publishingYearField(), '2025');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataByProjectId['p1']?.publishedDate, '2025');
  });

  testWidgets('published date year-month round trip', (tester) async {
    gateway.metadataByProjectId['p1'] = kMetadataPanelFixture.copyWith(
      publishedDate: '2024-05',
    );

    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.epub,
    );
    await selectMetadataSection(tester, '常规');

    expect(
      tester.widget<TextFormField>(publishingYearField()).controller?.text,
      '2024',
    );
    expect(
      tester.widget<TextFormField>(publishingMonthField()).controller?.text,
      '5',
    );
    expect(
      tester.widget<TextFormField>(publishingDayField()).controller?.text,
      '',
    );

    await tester.enterText(publishingMonthField(), '6');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataByProjectId['p1']?.publishedDate, '2024-06');
  });

  testWidgets('published date full date round trip', (tester) async {
    gateway.metadataByProjectId['p1'] = kMetadataPanelFixture.copyWith(
      publishedDate: '2024-05-31',
    );

    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );
    await selectMetadataSection(tester, '常规');

    expect(
      tester.widget<TextFormField>(publishingYearField()).controller?.text,
      '2024',
    );
    expect(
      tester.widget<TextFormField>(publishingMonthField()).controller?.text,
      '5',
    );
    expect(
      tester.widget<TextFormField>(publishingDayField()).controller?.text,
      '31',
    );

    await tester.enterText(publishingDayField(), '15');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataByProjectId['p1']?.publishedDate, '2024-05-15');
  });

  testWidgets('debounced edit persists metadata without manual save', (
    tester,
  ) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );
    await selectSeriesSection(tester);

    await tester.enterText(numberTextField(), '2');
    await tester.pump(const Duration(milliseconds: 500));
    expect(gateway.metadataUpdateCallCount, 0);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 1);
    expect(gateway.metadataByProjectId['p1']?.number, '2');
    expect(find.text('保存中…'), findsNothing);
  });

  testWidgets('validation failure skips autosave until field is valid', (
    tester,
  ) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 0);
    expect(find.text('必填'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '新标题');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 1);
    expect(gateway.metadataByProjectId['p1']?.title, '新标题');
  });

  testWidgets('save failure shows retry and persists on retry', (tester) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );
    await selectSeriesSection(tester);

    gateway.nextMetadataUpdateError = Exception('磁盘写入失败');

    await tester.enterText(numberTextField(), '9');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 1);
    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(gateway.metadataByProjectId['p1']?.number, '01');

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 2);
    expect(gateway.metadataByProjectId['p1']?.number, '9');
    expect(find.textContaining('保存失败'), findsNothing);
  });

  testWidgets('page count change keeps pending field edits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: _MetadataPanelPageCountHarness(
              gateway: gateway,
              exportFormat: ExportFormatFrb.comicArchive,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await selectSeriesSection(tester);
    await tester.enterText(numberTextField(), '6');
    await tester.tap(find.text('增加页数'));
    await tester.pump();

    expect(
      tester.widget<TextFormField>(numberTextField()).controller?.text,
      '6',
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 1);
    expect(gateway.metadataByProjectId['p1']?.number, '6');
  });

  testWidgets('preserves field edits made while save result is applied', (
    tester,
  ) async {
    await pumpMetadataPanel(
      tester,
      gateway: gateway,
      exportFormat: ExportFormatFrb.comicArchive,
    );
    await selectSeriesSection(tester);

    final numberField = numberTextField();
    final controller = tester.widget<TextFormField>(numberField).controller!;

    await tester.enterText(numberField, '12');
    gateway.onMetadataUpdate = () {
      controller.text = '123';
      controller.selection = const TextSelection.collapsed(offset: 3);
    };

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.text, '123');
    expect(gateway.metadataByProjectId['p1']?.number, '12');

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataByProjectId['p1']?.number, '123');
  });
}

class _MetadataPanelPageCountHarness extends StatefulWidget {
  const _MetadataPanelPageCountHarness({
    required this.gateway,
    required this.exportFormat,
  });

  final InMemoryCoreGateway gateway;
  final ExportFormatFrb exportFormat;

  @override
  State<_MetadataPanelPageCountHarness> createState() =>
      _MetadataPanelPageCountHarnessState();
}

class _MetadataPanelPageCountHarnessState
    extends State<_MetadataPanelPageCountHarness> {
  int pageCount = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MetadataPanel(
            key: ValueKey(widget.exportFormat),
            projectId: 'p1',
            pageCount: pageCount,
            exportFormat: widget.exportFormat,
            gateway: widget.gateway,
          ),
        ),
        TextButton(
          onPressed: () => setState(() => pageCount += 2),
          child: const Text('增加页数'),
        ),
      ],
    );
  }
}

extension on Metadata {
  Metadata copyWith({String? publishedDate}) {
    return Metadata(
      title: title,
      series: series,
      number: number,
      seriesCount: seriesCount,
      publishedDate: publishedDate ?? this.publishedDate,
      languageIso: languageIso,
      author: author,
      tags: tags,
      characters: characters,
      ageRating: ageRating,
      description: description,
      coverPageIndex: coverPageIndex,
      pageCount: pageCount,
    );
  }
}

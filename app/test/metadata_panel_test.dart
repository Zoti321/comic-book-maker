import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_panel.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui/features/project_editor/metadata_panel_harness.dart';
import 'support/frb/rust_fake.dart';

void main() {
  late FakeRustLibApi fake;

  setUpAll(() {
    fake = FakeRustLibApi.metadataPanel();
    initRustTestFake(fake);
  });

  setUp(() {
    fake.metadataByProjectId['p1'] = kMetadataPanelFixture;
    fake.metadataUpdateCallCount = 0;
    fake.nextMetadataUpdateError = null;
    fake.failMetadataUpdates = false;
    fake.onMetadataUpdate = null;
  });
  testWidgets('comic archive export format shows ComicInfo fields', (tester) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.comicArchive);

    expect(find.text('导入元数据（只读）'), findsOneWidget);
    expect(
      find.textContaining('导入资源中没有元数据'),
      findsOneWidget,
    );
    expect(find.text('导出元数据'), findsOneWidget);
    expect(find.text('ComicInfo'), findsWidgets);
    expect(find.text('卷号'), findsOneWidget);
    expect(find.text('编辑模型'), findsNothing);
    expect(find.text('保存'), findsNothing);
    expect(find.text('未保存'), findsNothing);
  });

  testWidgets('epub export format shows OPF and fixed-layout sections', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.epub);

    expect(find.text('OPF Metadata'), findsWidgets);
    expect(find.text('标识符 (GTIN/ISBN)'), findsOneWidget);
    expect(find.text('rendition:layout'), findsNothing);

    await tester.tap(find.text('固定版式'));
    await tester.pumpAndSettle();

    expect(find.text('rendition:layout'), findsOneWidget);
    expect(find.text('pre-paginated'), findsOneWidget);
  });

  testWidgets('pdf export format shows placeholder without editable form', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.pdf);

    expect(find.textContaining('PDF Export 尚未实现'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
    expect(find.text('标题'), findsNothing);
  });

  testWidgets('debounced edit persists metadata without manual save', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.comicArchive);

    await tester.enterText(find.byType(TextFormField).last, '2');
    await tester.pump(const Duration(milliseconds: 500));
    expect(fake.metadataUpdateCallCount, 0);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 1);
    expect(fake.metadataByProjectId['p1']?.volume, '2');
    expect(find.text('保存中…'), findsNothing);
  });

  testWidgets('validation failure skips autosave until field is valid', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.comicArchive);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 0);
    expect(find.text('必填'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '新标题');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 1);
    expect(fake.metadataByProjectId['p1']?.title, '新标题');
  });

  testWidgets('save failure shows retry and persists on retry', (tester) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.comicArchive);

    fake.nextMetadataUpdateError = Exception('磁盘写入失败');

    await tester.enterText(find.byType(TextFormField).last, '9');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 1);
    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(fake.metadataByProjectId['p1']?.volume, '1');

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 2);
    expect(fake.metadataByProjectId['p1']?.volume, '9');
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
              exportFormat: ExportFormatFrb.comicArchive,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '6');
    await tester.tap(find.text('增加页数'));
    await tester.pump();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).last).controller?.text,
      '6',
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 1);
    expect(fake.metadataByProjectId['p1']?.volume, '6');
  });

  testWidgets('preserves field edits made while save result is applied', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.comicArchive);

    final volumeField = find.byType(TextFormField).last;
    final controller = tester.widget<TextFormField>(volumeField).controller!;

    await tester.enterText(volumeField, '12');
    fake.onMetadataUpdate = () {
      controller.text = '123';
      controller.selection = const TextSelection.collapsed(offset: 3);
    };

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.text, '123');
    expect(fake.metadataByProjectId['p1']?.volume, '12');

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(fake.metadataByProjectId['p1']?.volume, '123');
  });
}

class _MetadataPanelPageCountHarness extends StatefulWidget {
  const _MetadataPanelPageCountHarness({required this.exportFormat});

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

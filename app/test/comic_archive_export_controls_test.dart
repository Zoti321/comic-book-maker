import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/comic_archive_export_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows container menu and extension checkbox', (tester) async {
    var container = ComicArchiveContainerFrb.zip;
    var useComicExt = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComicArchiveExportControls(
            settings: ProjectSettings(
              exportFormat: ExportFormatFrb.comicArchive,
              inferredImportKind: InferredImportKindFrb.images,
              deleteProjectAfterExport: false,
              useDefaultExportDirectory: true,
              exportDirectory: null,
              comicArchiveContainer: container,
              useComicArchiveExtension: useComicExt,
            ),
            enabled: true,
            exampleBaseName: 'Demo',
            onContainerChanged: (value) => container = value,
            onUseComicExtensionChanged: (value) => useComicExt = value,
          ),
        ),
      ),
    );

    expect(find.textContaining('压缩算法：ZIP'), findsOneWidget);
    expect(find.textContaining('Demo.cbz'), findsOneWidget);
    expect(find.text('使用漫画扩展名'), findsOneWidget);
  });
}

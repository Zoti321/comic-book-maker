import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/features/settings/comic_archive_export_controls.dart';
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

    expect(find.text('压缩算法'), findsOneWidget);
    expect(find.text('ZIP'), findsOneWidget);
    expect(find.textContaining('Demo.cbz'), findsOneWidget);
    expect(find.text('使用漫画扩展名'), findsOneWidget);
    expect(
      find.text('当前算法尚未实现 Export，请改用 ZIP 或等待后续版本。'),
      findsNothing,
    );
  });

  testWidgets('RAR container is selectable without not-implemented warning',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComicArchiveExportControls(
            settings: const ProjectSettings(
              exportFormat: ExportFormatFrb.comicArchive,
              inferredImportKind: InferredImportKindFrb.images,
              deleteProjectAfterExport: false,
              useDefaultExportDirectory: true,
              exportDirectory: null,
              comicArchiveContainer: ComicArchiveContainerFrb.rar,
              useComicArchiveExtension: true,
            ),
            enabled: true,
            exampleBaseName: 'Demo',
            onContainerChanged: (_) {},
            onUseComicExtensionChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('RAR'), findsOneWidget);
    expect(find.textContaining('Demo.cbr'), findsOneWidget);
    expect(
      find.text('当前算法尚未实现 Export，请改用 ZIP 或等待后续版本。'),
      findsNothing,
    );
  });
}

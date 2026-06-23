import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/mobile_export_platform.dart';
import 'package:comic_book_maker/ui/features/settings/project_export_settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frb/rust_fake.dart';

void main() {
  rustTestSetUpAll();

  tearDown(resetMobileExportSaveFileOverride);

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectExportSettingsPanel(
            settings: const ProjectSettings(
              exportFormat: ExportFormatFrb.comicArchive,
              inferredImportKind: InferredImportKindFrb.images,
              deleteProjectAfterExport: false,
              useDefaultExportDirectory: false,
              exportDirectory: null,
              comicArchiveContainer: ComicArchiveContainerFrb.zip,
              useComicArchiveExtension: true,
            ),
            enabled: true,
            onExportFormatChanged: (_) {},
            onContainerChanged: (_) {},
            onUseComicExtensionChanged: (_) {},
            onUseDefaultDirectoryChanged: (_) {},
            onExportDirectoryChanged: (_) {},
            onDeleteAfterExportChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows export directory settings on desktop-like platforms', (
    tester,
  ) async {
    mobileExportSaveFileOverride = () => false;
    await pumpPanel(tester);

    expect(find.text('使用默认导出目录'), findsOneWidget);
    expect(find.text('选择导出目录'), findsOneWidget);
  });

  testWidgets('hides export directory settings on mobile save-file platforms', (
    tester,
  ) async {
    mobileExportSaveFileOverride = () => true;
    await pumpPanel(tester);

    expect(find.text('使用默认导出目录'), findsNothing);
    expect(find.text('选择导出目录'), findsNothing);
    expect(find.text('导出格式'), findsOneWidget);
  });
}

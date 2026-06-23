import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:comic_book_maker/domain/use_cases/mobile_export_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

const _settings = ProjectSettings(
  exportFormat: ExportFormatFrb.comicArchive,
  inferredImportKind: InferredImportKindFrb.images,
  deleteProjectAfterExport: true,
  useDefaultExportDirectory: false,
  exportDirectory: r'C:\project-out',
  comicArchiveContainer: ComicArchiveContainerFrb.zip,
  useComicArchiveExtension: false,
);

void main() {
  test('mobileExportPlanningSettings ignores project export directory', () {
    final planned = mobileExportPlanningSettings(_settings);

    expect(planned.useDefaultExportDirectory, isTrue);
    expect(planned.exportDirectory, isNull);
    expect(planned.exportFormat, ExportFormatFrb.comicArchive);
    expect(planned.deleteProjectAfterExport, isTrue);
    expect(planned.comicArchiveContainer, ComicArchiveContainerFrb.zip);
    expect(planned.useComicArchiveExtension, isFalse);
  });

  test('targetWithDestination replaces destination path only', () {
    const template = ResolvedExportTarget(
      destinationPath: r'C:\temp\ignored.cbz',
      formatLabel: 'ZIP',
      exportComicArchive: true,
      comicArchiveContainer: ComicArchiveContainerFrb.zip,
      exportPdf: false,
    );

    final target = targetWithDestination(
      template: template,
      destinationPath: '/storage/emulated/0/Download/My Comic.zip',
    );

    expect(
      target.destinationPath,
      '/storage/emulated/0/Download/My Comic.zip',
    );
    expect(target.formatLabel, 'ZIP');
    expect(target.exportComicArchive, isTrue);
    expect(target.exportPdf, isFalse);
  });
}

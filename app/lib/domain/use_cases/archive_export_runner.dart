import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow_resolver.dart';

/// ?????????? Core ?? API?
class ArchiveExportRunner {
  ArchiveExportRunner({CoreGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final CoreGateway _gateway;

  Future<void> exportProject({
    required String projectId,
    required ResolvedExportTarget target,
    required bool deleteProjectAfterExport,
  }) {
    if (target.exportComicArchive) {
      switch (target.comicArchiveContainer) {
        case ComicArchiveContainerFrb.rar:
          return _gateway.exportCbr(
            projectId: projectId,
            destinationPath: target.destinationPath,
            deleteProjectAfterExport: deleteProjectAfterExport,
          );
        case ComicArchiveContainerFrb.zip:
        case ComicArchiveContainerFrb.sevenZip:
        case null:
          return _gateway.exportCbz(
            projectId: projectId,
            destinationPath: target.destinationPath,
            deleteProjectAfterExport: deleteProjectAfterExport,
          );
      }
    }
    return _gateway.exportEpub(
      projectId: projectId,
      destinationPath: target.destinationPath,
      deleteProjectAfterExport: deleteProjectAfterExport,
    );
  }
}

import 'package:comic_book_maker/application/core_gateway.dart';
import 'package:comic_book_maker/application/export_workflow_resolver.dart';

/// 按已解析目标路径调用 Core 导出 API。
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
      return _gateway.exportCbz(
        projectId: projectId,
        destinationPath: target.destinationPath,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );
    }
    return _gateway.exportEpub(
      projectId: projectId,
      destinationPath: target.destinationPath,
      deleteProjectAfterExport: deleteProjectAfterExport,
    );
  }
}

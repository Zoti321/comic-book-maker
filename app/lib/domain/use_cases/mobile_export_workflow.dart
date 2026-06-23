import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';

/// 移动端规划导出时忽略项目/全局目录设置，仅用于解析文件名与格式元数据。
ProjectSettings mobileExportPlanningSettings(ProjectSettings settings) {
  return ProjectSettings(
    exportFormat: settings.exportFormat,
    inferredImportKind: settings.inferredImportKind,
    deleteProjectAfterExport: settings.deleteProjectAfterExport,
    useDefaultExportDirectory: true,
    exportDirectory: null,
    comicArchiveContainer: settings.comicArchiveContainer,
    useComicArchiveExtension: settings.useComicArchiveExtension,
  );
}

ResolvedExportTarget targetWithDestination({
  required ResolvedExportTarget template,
  required String destinationPath,
}) {
  return ResolvedExportTarget(
    destinationPath: destinationPath,
    formatLabel: template.formatLabel,
    exportComicArchive: template.exportComicArchive,
    comicArchiveContainer: template.comicArchiveContainer,
    exportPdf: template.exportPdf,
  );
}

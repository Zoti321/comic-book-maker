import 'package:comic_book_maker/data/repositories/core_gateway.dart';

/// Builds an FRB update payload from the current persisted [ProjectSettings].
ProjectSettingsUpdate projectSettingsUpdateFrom(
  ProjectSettings settings, {
  ExportFormatFrb? exportFormat,
  bool? deleteProjectAfterExport,
  bool? useDefaultExportDirectory,
  String? exportDirectory,
  bool clearExportDirectory = false,
  ComicArchiveContainerFrb? comicArchiveContainer,
  bool? useComicArchiveExtension,
}) {
  return ProjectSettingsUpdate(
    exportFormat: exportFormat ?? settings.exportFormat,
    deleteProjectAfterExport:
        deleteProjectAfterExport ?? settings.deleteProjectAfterExport,
    useDefaultExportDirectory:
        useDefaultExportDirectory ?? settings.useDefaultExportDirectory,
    exportDirectory: clearExportDirectory
        ? null
        : (exportDirectory ?? settings.exportDirectory),
    comicArchiveContainer:
        comicArchiveContainer ?? settings.comicArchiveContainer,
    useComicArchiveExtension:
        useComicArchiveExtension ?? settings.useComicArchiveExtension,
  );
}

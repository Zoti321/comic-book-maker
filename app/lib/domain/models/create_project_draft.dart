import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_command.dart';
import 'package:comic_book_maker/domain/models/create_project_import_source.dart';
import 'package:comic_book_maker/domain/models/import_archive_format.dart';

export 'package:comic_book_maker/domain/models/create_project_import_source.dart'
    show
        CreateProjectArchiveImport,
        CreateProjectImageImport,
        CreateProjectImportSource;

/// [Create Project](CONTEXT.md) 向导表单状态（可变；持久化须经 [CreateProjectCommand]）。
class CreateProjectDraft {
  CreateProjectDraft({
    this.importSource,
    this.exportFormat = ExportFormatFrb.comicArchive,
    this.comicArchiveContainer = ComicArchiveContainerFrb.zip,
    this.useComicArchiveExtension = true,
    this.useDefaultExportDirectory = true,
    this.exportDirectory,
    this.deleteProjectAfterExport = false,
    this.projectTitle = '',
  });

  CreateProjectImportSource? importSource;
  ExportFormatFrb exportFormat;
  ComicArchiveContainerFrb comicArchiveContainer;
  bool useComicArchiveExtension;
  bool useDefaultExportDirectory;
  String? exportDirectory;
  bool deleteProjectAfterExport;
  String projectTitle;

  InferredImportKindFrb? get inferredImportKind {
    final source = importSource;
    if (source == null) return null;
    return switch (source) {
      CreateProjectImageImport() => InferredImportKindFrb.images,
      CreateProjectArchiveImport(:final format) => switch (format) {
          ImportArchiveFormat.cbz => InferredImportKindFrb.comicArchive,
          ImportArchiveFormat.cbr => InferredImportKindFrb.comicArchive,
          ImportArchiveFormat.cb7 => InferredImportKindFrb.comicArchive,
          ImportArchiveFormat.epub => InferredImportKindFrb.epub,
        },
    };
  }

  String? get createDisabledReason {
    if (importSource == null) {
      return '请先在「导入」中选择要导入的资源';
    }
    if (!useDefaultExportDirectory) {
      final dir = exportDirectory?.trim();
      if (dir == null || dir.isEmpty) {
        return '请在「导出」中配置专用导出目录，或改为沿用全局默认目录';
      }
    }
    return null;
  }

  bool get canCreate => createDisabledReason == null;

  String? get effectiveTitle {
    final trimmed = projectTitle.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 将已填写的向导状态转为 [CreateProjectCommand]。
  CreateProjectCommand toCommand() {
    final reason = createDisabledReason;
    if (reason != null) {
      throw CreateProjectValidationException(reason);
    }
    return CreateProjectCommand(
      title: effectiveTitle,
      importSource: importSource!,
      settingsUpdate: toSettingsUpdate(),
    );
  }

  ProjectSettingsUpdate toSettingsUpdate() {
    return ProjectSettingsUpdate(
      exportFormat: exportFormat,
      deleteProjectAfterExport: deleteProjectAfterExport,
      useDefaultExportDirectory: useDefaultExportDirectory,
      exportDirectory: useDefaultExportDirectory ? null : exportDirectory?.trim(),
      comicArchiveContainer: comicArchiveContainer,
      useComicArchiveExtension: useComicArchiveExtension,
    );
  }

  CreateProjectDraft copyWith({
    CreateProjectImportSource? importSource,
    ExportFormatFrb? exportFormat,
    ComicArchiveContainerFrb? comicArchiveContainer,
    bool? useComicArchiveExtension,
    bool? useDefaultExportDirectory,
    String? exportDirectory,
    bool clearExportDirectory = false,
    bool? deleteProjectAfterExport,
    String? projectTitle,
  }) {
    return CreateProjectDraft(
      importSource: importSource ?? this.importSource,
      exportFormat: exportFormat ?? this.exportFormat,
      comicArchiveContainer: comicArchiveContainer ?? this.comicArchiveContainer,
      useComicArchiveExtension:
          useComicArchiveExtension ?? this.useComicArchiveExtension,
      useDefaultExportDirectory:
          useDefaultExportDirectory ?? this.useDefaultExportDirectory,
      exportDirectory: clearExportDirectory
          ? null
          : (exportDirectory ?? this.exportDirectory),
      deleteProjectAfterExport:
          deleteProjectAfterExport ?? this.deleteProjectAfterExport,
      projectTitle: projectTitle ?? this.projectTitle,
    );
  }

  void applyImportSource(CreateProjectImportSource source) {
    importSource = source;
    exportFormat = switch (inferredImportKind) {
      InferredImportKindFrb.epub => ExportFormatFrb.epub,
      InferredImportKindFrb.images ||
      InferredImportKindFrb.comicArchive ||
      null =>
        ExportFormatFrb.comicArchive,
      InferredImportKindFrb.pdf => ExportFormatFrb.comicArchive,
    };
  }
}

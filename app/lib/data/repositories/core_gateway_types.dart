import 'package:comic_book_maker/src/rust/api/metadata.dart' as metadata_api;
import 'package:comic_book_maker/src/rust/api/simple.dart' as simple_api;

export 'package:comic_book_maker/src/rust/api/metadata.dart'
    show
        Metadata,
        MetadataEditorSchemaFrb,
        MetadataFieldKindFrb,
        MetadataFieldSpecFrb,
        MetadataFieldValueFrb,
        MetadataSectionSpecFrb;
export 'package:comic_book_maker/src/rust/api/simple.dart'
    show
        AppendImportResult,
        ArchiveFormatFrb,
        ComicArchiveContainerFrb,
        ExportFormatFrb,
        ImportCbzResult,
        InferredImportKindFrb,
        PageSummary,
        ProjectSettings,
        ProjectSettingsUpdate,
        ProjectSummary;

/// [Create Project](CONTEXT.md) 的 Import 来源（用例级，不依赖 UI draft）。
sealed class CreateProjectImportSpec {
  const CreateProjectImportSpec();
}

/// 从 Page Image 列表创建 Project。
final class CreateProjectFromImages extends CreateProjectImportSpec {
  const CreateProjectFromImages(this.sourcePaths);

  final List<String> sourcePaths;
}

/// 从 Archive Format 创建 Project。
final class CreateProjectFromArchive extends CreateProjectImportSpec {
  const CreateProjectFromArchive({
    required this.format,
    required this.sourcePath,
  });

  final simple_api.ArchiveFormatFrb format;
  final String sourcePath;
}

/// Create Project 用例请求：创建 + Import + 写入 ProjectSettings + 可选标题。
class CreateProjectWithImportRequest {
  const CreateProjectWithImportRequest({
    this.title,
    required this.import,
    required this.settingsUpdate,
  });

  final String? title;
  final CreateProjectImportSpec import;
  final simple_api.ProjectSettingsUpdate settingsUpdate;
}

/// 项目编辑页加载快照（pages + settings + Cover 索引）。
class ProjectEditorSnapshot {
  const ProjectEditorSnapshot({
    required this.pages,
    required this.settings,
    required this.coverPageIndex,
  });

  final List<simple_api.PageSummary> pages;
  final simple_api.ProjectSettings settings;
  final int coverPageIndex;
}

/// Metadata 编辑会话加载上下文。
class MetadataEditingContext {
  const MetadataEditingContext({
    required this.metadata,
    required this.inferredImportKind,
  });

  final metadata_api.Metadata metadata;
  final simple_api.InferredImportKindFrb inferredImportKind;
}

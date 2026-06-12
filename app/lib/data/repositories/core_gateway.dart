import 'package:comic_book_maker/data/repositories/export_failure_mapper.dart';
import 'package:comic_book_maker/data/repositories/metadata_patch.dart';
import 'package:comic_book_maker/src/rust/api/metadata.dart' as metadata_api;
import 'package:comic_book_maker/src/rust/api/simple.dart' as simple_api;
import 'package:comic_book_maker/src/rust/export_error.dart';

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
        ComicArchiveContainerFrb,
        ExportFormatFrb,
        ImportCbzResult,
        ImportMetadataKindFrb,
        ImportMetadataSnapshotFrb,
        InferredImportKindFrb,
        PageSummary,
        ProjectSettings,
        ProjectSettingsUpdate,
        ProjectSummary;

/// [Archive Format](CONTEXT.md) 种类，供 Import / Export / Append 统一分发。
enum ArchiveFormatKind { cbz, cbr, cb7, epub }

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

  final ArchiveFormatKind format;
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
    required this.importSnapshot,
    required this.inferredImportKind,
  });

  final metadata_api.Metadata metadata;
  final simple_api.ImportMetadataSnapshotFrb importSnapshot;
  final simple_api.InferredImportKindFrb inferredImportKind;
}

/// Metadata 表单与纯变换（无 projectId）；[CoreGateway] 接缝的子集。
abstract class MetadataEditingGateway {
  metadata_api.MetadataEditorSchemaFrb getMetadataEditorSchema({
    required simple_api.ExportFormatFrb exportFormat,
  });
  metadata_api.Metadata metadataWithPageCount({
    required metadata_api.Metadata metadata,
    required int pageCount,
  });
  metadata_api.Metadata metadataWithDropdownField({
    required metadata_api.Metadata metadata,
    required String fieldId,
    String? value,
  });
  metadata_api.Metadata metadataWithCoverPageIndex({
    required metadata_api.Metadata metadata,
    required int coverPageIndex,
  });
  String metadataFieldDisplayValue({
    required metadata_api.Metadata metadata,
    required String fieldId,
  });
  metadata_api.Metadata mergeMetadataFromForm({
    required simple_api.ExportFormatFrb exportFormat,
    required metadata_api.Metadata base,
    required List<metadata_api.MetadataFieldValueFrb> fieldValues,
    required int pageCount,
  });
}

/// Repository 接缝：封装 FRB（`lib/src/rust`），供 domain / providers / UI 访问 Core。
abstract class CoreGateway implements MetadataEditingGateway {
  // —— Library ——
  List<simple_api.ProjectSummary> listProjects();
  void touchProject({required String projectId});
  void deleteProject({required String projectId});

  // —— Create Project ——
  /// Create Project 用例：创建 + Import + 写入 ProjectSettings + 可选标题覆盖。
  simple_api.ProjectSummary createProjectWithImport(
    CreateProjectWithImportRequest request,
  );

  /// 仅更新 Metadata 标题并持久化。
  void patchProjectMetadataTitle({
    required String projectId,
    required String title,
  });

  // —— Import / Append（Archive Format 统一入口）——
  simple_api.ImportCbzResult importArchive({
    required ArchiveFormatKind format,
    required String sourcePath,
  });
  simple_api.AppendImportResult appendArchive({
    required String projectId,
    required ArchiveFormatKind format,
    required String sourcePath,
  });
  List<simple_api.PageSummary> addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  });

  // —— Project settings ——
  simple_api.ProjectSettings getProjectSettings({required String projectId});
  simple_api.ProjectSettings updateProjectSettings({
    required String projectId,
    required simple_api.ProjectSettingsUpdate update,
  });
  simple_api.ProjectSettings changeProjectInferredImportKind({
    required String projectId,
    required simple_api.InferredImportKindFrb inferredImportKind,
  });

  // —— Metadata（持久化 + 导入快照）——
  metadata_api.Metadata getProjectMetadata({required String projectId});
  metadata_api.Metadata updateProjectMetadata({
    required String projectId,
    required metadata_api.Metadata metadata,
  });
  simple_api.ImportMetadataSnapshotFrb getImportMetadataSnapshot({
    required String projectId,
  });

  /// 设置 Cover 并持久化；返回更新后的 `coverPageIndex`。
  int setProjectCoverPage({
    required String projectId,
    required int coverPageIndex,
    required int pageCount,
  });

  // —— Project 编辑会话 ——
  ProjectEditorSnapshot loadProjectEditorSnapshot({required String projectId});

  MetadataEditingContext loadMetadataEditingContext({
    required String projectId,
  });

  // —— Page Operation ——
  List<simple_api.PageSummary> listPages({required String projectId});
  void deletePage({required String projectId, required String pageId});
  simple_api.PageSummary replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  });
  List<simple_api.PageSummary> reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  });

  // —— Export（Archive Format 统一入口）——
  Future<void> exportArchive({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    simple_api.ComicArchiveContainerFrb? comicArchiveContainer,
    required bool exportPdf,
    required bool deleteProjectAfterExport,
  });
}

/// 生产环境：薄适配 FRB 生成 API；格式分发内聚于 implementation。
class FrbCoreGateway implements CoreGateway {
  const FrbCoreGateway();

  @override
  List<simple_api.ProjectSummary> listProjects() => simple_api.listProjects();

  @override
  void touchProject({required String projectId}) =>
      simple_api.touchProject(projectId: projectId);

  @override
  void deleteProject({required String projectId}) =>
      simple_api.deleteProject(projectId: projectId);

  @override
  simple_api.ProjectSummary createProjectWithImport(
    CreateProjectWithImportRequest request,
  ) {
    final project = switch (request.import) {
      CreateProjectFromImages(:final sourcePaths) =>
        _createProjectFromImages(
          title: request.title,
          sourcePaths: sourcePaths,
          settingsUpdate: request.settingsUpdate,
        ),
      CreateProjectFromArchive(:final format, :final sourcePath) =>
        _createProjectFromArchive(
          format: format,
          sourcePath: sourcePath,
          settingsUpdate: request.settingsUpdate,
        ),
    };
    return _projectWithOptionalTitle(project, request.title);
  }

  simple_api.ProjectSummary _createProjectFromImages({
    required String? title,
    required List<String> sourcePaths,
    required simple_api.ProjectSettingsUpdate settingsUpdate,
  }) {
    final created = simple_api.createProject(title: title);
    simple_api.addPageImages(
      projectId: created.id,
      sourcePaths: sourcePaths,
    );
    simple_api.updateProjectSettings(
      projectId: created.id,
      update: settingsUpdate,
    );
    return created;
  }

  simple_api.ProjectSummary _createProjectFromArchive({
    required ArchiveFormatKind format,
    required String sourcePath,
    required simple_api.ProjectSettingsUpdate settingsUpdate,
  }) {
    final imported = importArchive(format: format, sourcePath: sourcePath);
    simple_api.updateProjectSettings(
      projectId: imported.project.id,
      update: settingsUpdate,
    );
    return imported.project;
  }

  simple_api.ProjectSummary _projectWithOptionalTitle(
    simple_api.ProjectSummary project,
    String? title,
  ) {
    if (title == null || title == project.title) {
      return project;
    }
    patchProjectMetadataTitle(projectId: project.id, title: title);
    return simple_api.ProjectSummary(
      id: project.id,
      title: title,
      updatedAtMs: project.updatedAtMs,
      createdAtMs: project.createdAtMs,
      lastOpenedAtMs: project.lastOpenedAtMs,
      coverThumbnailPath: project.coverThumbnailPath,
    );
  }

  @override
  void patchProjectMetadataTitle({
    required String projectId,
    required String title,
  }) {
    final metadata = metadata_api.getProjectMetadata(projectId: projectId);
    metadata_api.updateProjectMetadata(
      projectId: projectId,
      metadata: metadataWithTitle(metadata, title),
    );
  }

  @override
  ProjectEditorSnapshot loadProjectEditorSnapshot({required String projectId}) {
    final pages = simple_api.listPages(projectId: projectId);
    final settings = simple_api.getProjectSettings(projectId: projectId);
    var coverPageIndex = 0;
    try {
      coverPageIndex =
          metadata_api.getProjectMetadata(projectId: projectId).coverPageIndex;
    } catch (_) {}
    return ProjectEditorSnapshot(
      pages: pages,
      settings: settings,
      coverPageIndex: coverPageIndex,
    );
  }

  @override
  MetadataEditingContext loadMetadataEditingContext({
    required String projectId,
  }) {
    return MetadataEditingContext(
      metadata: metadata_api.getProjectMetadata(projectId: projectId),
      importSnapshot: simple_api.getImportMetadataSnapshot(
        projectId: projectId,
      ),
      inferredImportKind:
          simple_api.getProjectSettings(projectId: projectId).inferredImportKind,
    );
  }

  @override
  simple_api.ImportCbzResult importArchive({
    required ArchiveFormatKind format,
    required String sourcePath,
  }) =>
      switch (format) {
        ArchiveFormatKind.cbz =>
          simple_api.importCbz(sourcePath: sourcePath),
        ArchiveFormatKind.cbr =>
          simple_api.importCbr(sourcePath: sourcePath),
        ArchiveFormatKind.cb7 =>
          simple_api.importCb7(sourcePath: sourcePath),
        ArchiveFormatKind.epub =>
          simple_api.importEpub(sourcePath: sourcePath),
      };

  @override
  simple_api.AppendImportResult appendArchive({
    required String projectId,
    required ArchiveFormatKind format,
    required String sourcePath,
  }) =>
      switch (format) {
        ArchiveFormatKind.cbz => simple_api.appendCbz(
            projectId: projectId,
            sourcePath: sourcePath,
          ),
        ArchiveFormatKind.cbr => simple_api.appendCbr(
            projectId: projectId,
            sourcePath: sourcePath,
          ),
        ArchiveFormatKind.cb7 => simple_api.appendCb7(
            projectId: projectId,
            sourcePath: sourcePath,
          ),
        ArchiveFormatKind.epub => simple_api.appendEpub(
            projectId: projectId,
            sourcePath: sourcePath,
          ),
      };

  @override
  List<simple_api.PageSummary> addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) =>
      simple_api.addPageImages(
        projectId: projectId,
        sourcePaths: sourcePaths,
      );

  @override
  simple_api.ProjectSettings getProjectSettings({required String projectId}) =>
      simple_api.getProjectSettings(projectId: projectId);

  @override
  simple_api.ProjectSettings updateProjectSettings({
    required String projectId,
    required simple_api.ProjectSettingsUpdate update,
  }) =>
      simple_api.updateProjectSettings(
        projectId: projectId,
        update: update,
      );

  @override
  metadata_api.Metadata getProjectMetadata({required String projectId}) =>
      metadata_api.getProjectMetadata(projectId: projectId);

  @override
  metadata_api.Metadata updateProjectMetadata({
    required String projectId,
    required metadata_api.Metadata metadata,
  }) =>
      metadata_api.updateProjectMetadata(
        projectId: projectId,
        metadata: metadata,
      );

  @override
  simple_api.ImportMetadataSnapshotFrb getImportMetadataSnapshot({
    required String projectId,
  }) =>
      simple_api.getImportMetadataSnapshot(projectId: projectId);

  @override
  metadata_api.MetadataEditorSchemaFrb getMetadataEditorSchema({
    required simple_api.ExportFormatFrb exportFormat,
  }) =>
      metadata_api.getMetadataEditorSchema(exportFormat: exportFormat);

  @override
  metadata_api.Metadata metadataWithPageCount({
    required metadata_api.Metadata metadata,
    required int pageCount,
  }) =>
      metadata_api.metadataWithPageCount(
        metadata: metadata,
        pageCount: pageCount,
      );

  @override
  metadata_api.Metadata metadataWithDropdownField({
    required metadata_api.Metadata metadata,
    required String fieldId,
    String? value,
  }) =>
      metadata_api.metadataWithDropdownField(
        metadata: metadata,
        fieldId: fieldId,
        value: value,
      );

  @override
  metadata_api.Metadata metadataWithCoverPageIndex({
    required metadata_api.Metadata metadata,
    required int coverPageIndex,
  }) =>
      metadata_api.metadataWithCoverPageIndex(
        metadata: metadata,
        coverPageIndex: coverPageIndex,
      );

  @override
  String metadataFieldDisplayValue({
    required metadata_api.Metadata metadata,
    required String fieldId,
  }) =>
      metadata_api.metadataFieldDisplayValue(
        metadata: metadata,
        fieldId: fieldId,
      );

  @override
  metadata_api.Metadata mergeMetadataFromForm({
    required simple_api.ExportFormatFrb exportFormat,
    required metadata_api.Metadata base,
    required List<metadata_api.MetadataFieldValueFrb> fieldValues,
    required int pageCount,
  }) =>
      metadata_api.mergeMetadataFromForm(
        exportFormat: exportFormat,
        base: base,
        fieldValues: fieldValues,
        pageCount: pageCount,
      );

  @override
  int setProjectCoverPage({
    required String projectId,
    required int coverPageIndex,
    required int pageCount,
  }) {
    final metadata = metadata_api.getProjectMetadata(projectId: projectId);
    final patched = metadata_api.metadataWithCoverPageIndex(
      metadata: metadata_api.metadataWithPageCount(
        metadata: metadata,
        pageCount: pageCount,
      ),
      coverPageIndex: coverPageIndex,
    );
    final updated = metadata_api.updateProjectMetadata(
      projectId: projectId,
      metadata: patched,
    );
    return updated.coverPageIndex;
  }

  @override
  simple_api.ProjectSettings changeProjectInferredImportKind({
    required String projectId,
    required simple_api.InferredImportKindFrb inferredImportKind,
  }) =>
      simple_api.changeProjectInferredImportKind(
        projectId: projectId,
        inferredImportKind: inferredImportKind,
      );

  @override
  List<simple_api.PageSummary> listPages({required String projectId}) =>
      simple_api.listPages(projectId: projectId);

  @override
  void deletePage({required String projectId, required String pageId}) =>
      simple_api.deletePage(projectId: projectId, pageId: pageId);

  @override
  simple_api.PageSummary replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) =>
      simple_api.replacePageImage(
        projectId: projectId,
        pageId: pageId,
        sourcePath: sourcePath,
      );

  @override
  List<simple_api.PageSummary> reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) =>
      simple_api.reorderPages(
        projectId: projectId,
        orderedPageIds: orderedPageIds,
      );

  @override
  Future<void> exportArchive({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    simple_api.ComicArchiveContainerFrb? comicArchiveContainer,
    required bool exportPdf,
    required bool deleteProjectAfterExport,
  }) async {
    try {
      if (exportPdf) {
        await simple_api.exportPdf(
          projectId: projectId,
          destinationPath: destinationPath,
          deleteProjectAfterExport: deleteProjectAfterExport,
        );
      } else if (exportComicArchive) {
        switch (comicArchiveContainer) {
          case simple_api.ComicArchiveContainerFrb.rar:
            await simple_api.exportCbr(
              projectId: projectId,
              destinationPath: destinationPath,
              deleteProjectAfterExport: deleteProjectAfterExport,
            );
          case simple_api.ComicArchiveContainerFrb.sevenZip:
            await simple_api.exportCb7(
              projectId: projectId,
              destinationPath: destinationPath,
              deleteProjectAfterExport: deleteProjectAfterExport,
            );
          case simple_api.ComicArchiveContainerFrb.zip:
          case null:
            await simple_api.exportCbz(
              projectId: projectId,
              destinationPath: destinationPath,
              deleteProjectAfterExport: deleteProjectAfterExport,
            );
        }
      } else {
        await simple_api.exportEpub(
          projectId: projectId,
          destinationPath: destinationPath,
          deleteProjectAfterExport: deleteProjectAfterExport,
        );
      }
    } on ExportError catch (error) {
      throw mapExportError(error);
    }
  }
}

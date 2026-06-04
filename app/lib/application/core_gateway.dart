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
        ComicArchiveContainerFrb,
        ExportFormatFrb,
        ImportCbzResult,
        ImportMetadataSnapshotFrb,
        InferredImportKindFrb,
        PageSummary,
        ProjectSettings,
        ProjectSettingsUpdate,
        ProjectSummary;

/// 应用层访问 Core 的统一接缝（≈ `simple.dart` + `metadata.dart` 公开 API）。
abstract class CoreGateway {
  List<simple_api.ProjectSummary> listProjects();
  void touchProject({required String projectId});
  void deleteProject({required String projectId});
  simple_api.ProjectSummary createProject({String? title});
  simple_api.ImportCbzResult importCbz({required String sourcePath});
  simple_api.ImportCbzResult importCbr({required String sourcePath});
  simple_api.ImportCbzResult importEpub({required String sourcePath});
  List<simple_api.PageSummary> addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  });
  simple_api.ProjectSettings getProjectSettings({required String projectId});
  simple_api.ProjectSettings updateProjectSettings({
    required String projectId,
    required simple_api.ProjectSettingsUpdate update,
  });

  metadata_api.Metadata getProjectMetadata({required String projectId});
  metadata_api.Metadata updateProjectMetadata({
    required String projectId,
    required metadata_api.Metadata metadata,
  });
  simple_api.ImportMetadataSnapshotFrb getImportMetadataSnapshot({
    required String projectId,
  });
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

  simple_api.ProjectSettings changeProjectInferredImportKind({
    required String projectId,
    required simple_api.InferredImportKindFrb inferredImportKind,
  });
  List<simple_api.PageSummary> listPages({required String projectId});
  simple_api.AppendImportResult appendCbz({
    required String projectId,
    required String sourcePath,
  });
  simple_api.AppendImportResult appendCbr({
    required String projectId,
    required String sourcePath,
  });
  simple_api.AppendImportResult appendEpub({
    required String projectId,
    required String sourcePath,
  });
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
  Future<void> exportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  });
  Future<void> exportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  });
}

/// 生产环境：薄适配 FRB 生成 API。
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
  simple_api.ProjectSummary createProject({String? title}) =>
      simple_api.createProject(title: title);

  @override
  simple_api.ImportCbzResult importCbz({required String sourcePath}) =>
      simple_api.importCbz(sourcePath: sourcePath);

  @override
  simple_api.ImportCbzResult importCbr({required String sourcePath}) =>
      simple_api.importCbr(sourcePath: sourcePath);

  @override
  simple_api.ImportCbzResult importEpub({required String sourcePath}) =>
      simple_api.importEpub(sourcePath: sourcePath);

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
  simple_api.AppendImportResult appendCbz({
    required String projectId,
    required String sourcePath,
  }) =>
      simple_api.appendCbz(projectId: projectId, sourcePath: sourcePath);

  @override
  simple_api.AppendImportResult appendCbr({
    required String projectId,
    required String sourcePath,
  }) =>
      simple_api.appendCbr(projectId: projectId, sourcePath: sourcePath);

  @override
  simple_api.AppendImportResult appendEpub({
    required String projectId,
    required String sourcePath,
  }) =>
      simple_api.appendEpub(projectId: projectId, sourcePath: sourcePath);

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
  Future<void> exportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      simple_api.exportCbz(
        projectId: projectId,
        destinationPath: destinationPath,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Future<void> exportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      simple_api.exportEpub(
        projectId: projectId,
        destinationPath: destinationPath,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );
}

import 'package:comic_book_maker/data/repositories/metadata_patch.dart';
import 'package:comic_book_maker/domain/models/project_page_structure.dart';
import 'package:comic_book_maker/src/rust/api/metadata.dart' as metadata_api;
import 'package:comic_book_maker/src/rust/api/simple.dart' as simple_api;
import 'package:comic_book_maker/src/rust/export_error.dart';

import 'core_gateway_types.dart';
import 'gateways/archive_gateway.dart';
import 'gateways/export_gateway.dart';
import 'gateways/library_gateway.dart';
import 'gateways/metadata_session_gateway.dart';
import 'gateways/project_editor_gateway.dart';
import 'gateways/project_settings_gateway.dart';

export 'core_gateway_types.dart';
export 'gateways/archive_gateway.dart';
export 'gateways/export_gateway.dart';
export 'gateways/library_gateway.dart';
export 'gateways/metadata_editing_gateway.dart';
export 'gateways/metadata_persistence_gateway.dart';
export 'gateways/metadata_session_gateway.dart';
export 'gateways/project_editor_gateway.dart';
export 'gateways/project_settings_gateway.dart';

/// 生产环境接缝：组合各用例 [Gateway]；实现仍委托 FRB。
abstract class CoreGateway
    implements
        LibraryGateway,
        ArchiveGateway,
        ProjectSettingsGateway,
        ProjectEditorGateway,
        MetadataSessionGateway,
        ExportGateway {}

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
    required simple_api.ArchiveFormatFrb format,
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
    return updateProjectTitle(projectId: project.id, title: title);
  }

  @override
  simple_api.ProjectSummary updateProjectTitle({
    required String projectId,
    required String title,
  }) {
    return simple_api.updateProjectTitle(projectId: projectId, title: title);
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
    final snapshot =
        simple_api.loadProjectEditorSnapshot(projectId: projectId);
    return ProjectEditorSnapshot(
      pages: snapshot.pages,
      settings: snapshot.settings,
      coverPageIndex: snapshot.coverPageIndex,
    );
  }

  @override
  MetadataEditingContext loadMetadataEditingContext({
    required String projectId,
  }) {
    return MetadataEditingContext(
      metadata: metadata_api.getProjectMetadata(projectId: projectId),
      inferredImportKind:
          simple_api.getProjectSettings(projectId: projectId).inferredImportKind,
    );
  }

  @override
  simple_api.ImportCbzResult importArchive({
    required simple_api.ArchiveFormatFrb format,
    required String sourcePath,
  }) =>
      simple_api.importArchive(format: format, sourcePath: sourcePath);

  @override
  simple_api.AppendImportResult appendArchive({
    required String projectId,
    required simple_api.ArchiveFormatFrb format,
    required String sourcePath,
  }) =>
      simple_api.appendArchive(
        projectId: projectId,
        format: format,
        sourcePath: sourcePath,
      );

  @override
  ProjectPageStructure addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) =>
      _mapPageStructure(
        simple_api.addPageImages(
          projectId: projectId,
          sourcePaths: sourcePaths,
        ),
      );

  @override
  ProjectPageStructure loadPageStructure({required String projectId}) =>
      _mapPageStructure(
        simple_api.loadPageStructure(projectId: projectId),
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
  }) =>
      simple_api.setCoverPage(
        projectId: projectId,
        coverPageIndex: coverPageIndex,
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
  ProjectPageStructure deletePage({
    required String projectId,
    required String pageId,
  }) =>
      _mapPageStructure(
        simple_api.deletePage(projectId: projectId, pageId: pageId),
      );

  @override
  ProjectPageStructure replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) =>
      _mapPageStructure(
        simple_api.replacePageImage(
          projectId: projectId,
          pageId: pageId,
          sourcePath: sourcePath,
        ),
      );

  @override
  ProjectPageStructure reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) =>
      _mapPageStructure(
        simple_api.reorderPages(
          projectId: projectId,
          orderedPageIds: orderedPageIds,
        ),
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
    } on ExportError {
      rethrow;
    }
  }
}

ProjectPageStructure _mapPageStructure(simple_api.ProjectPageStructureFrb structure) {
  return ProjectPageStructure(
    pages: structure.pages,
    coverPageIndex: structure.coverPageIndex,
  );
}


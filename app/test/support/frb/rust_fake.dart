import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/project_page_structure.dart';
import 'package:comic_book_maker/src/rust/api/export.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/export_error.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/repositories/in_memory_core_gateway.dart';

export '../data/repositories/in_memory_core_gateway.dart'
    show
        InMemoryCoreGateway,
        kEmptyLibraryMetadata,
        kMetadataPanelFixture;

bool _mockInitialized = false;

/// Widget / 导航测试：不加载动态库，FRB 调用委托 [InMemoryCoreGateway]。
void initRustTestFake({InMemoryCoreGateway? gateway}) {
  if (_mockInitialized) return;
  RustLib.initMock(
    api: FakeRustLibApi(gateway ?? InMemoryCoreGateway.emptyLibrary()),
  );
  _mockInitialized = true;
}

void rustTestSetUpAll({InMemoryCoreGateway Function()? gatewayFactory}) {
  setUpAll(() {
    initRustTestFake(gateway: gatewayFactory?.call());
  });
}

ProjectPageStructureFrb _toFrbStructure(ProjectPageStructure structure) {
  return ProjectPageStructureFrb(
    pages: structure.pages,
    coverPageIndex: structure.coverPageIndex,
  );
}

ProjectEditorSnapshotFrb _toEditorSnapshot(ProjectEditorSnapshot snapshot) {
  return ProjectEditorSnapshotFrb(
    pages: snapshot.pages,
    settings: snapshot.settings,
    coverPageIndex: snapshot.coverPageIndex,
  );
}

/// 完整 [RustLibApi] 实现，供 `RustLib.initMock` 使用。
class FakeRustLibApi extends RustLibApi {
  FakeRustLibApi(this._gateway);

  final CoreGateway _gateway;

  factory FakeRustLibApi.emptyLibrary() =>
      FakeRustLibApi(InMemoryCoreGateway.emptyLibrary());

  factory FakeRustLibApi.metadataPanel() =>
      FakeRustLibApi(InMemoryCoreGateway.metadataPanel());

  factory FakeRustLibApi.editorProject({int pageCount = 1}) =>
      FakeRustLibApi(InMemoryCoreGateway.editorProject(pageCount: pageCount));

  InMemoryCoreGateway get gateway => _gateway as InMemoryCoreGateway;

  @override
  ProjectPageStructureFrb crateApiSimpleAddPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) =>
      _toFrbStructure(
        _gateway.addPageImages(
          projectId: projectId,
          sourcePaths: sourcePaths,
        ),
      );

  @override
  AppendImportResult crateApiSimpleAppendArchive({
    required String projectId,
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) =>
      _gateway.appendArchive(
        projectId: projectId,
        format: format,
        sourcePath: sourcePath,
      );

  @override
  AppendImportResult crateApiSimpleAppendCb7({
    required String projectId,
    required String sourcePath,
  }) =>
      crateApiSimpleAppendArchive(
        projectId: projectId,
        format: ArchiveFormatFrb.cb7,
        sourcePath: sourcePath,
      );

  @override
  AppendImportResult crateApiSimpleAppendCbr({
    required String projectId,
    required String sourcePath,
  }) =>
      crateApiSimpleAppendArchive(
        projectId: projectId,
        format: ArchiveFormatFrb.cbr,
        sourcePath: sourcePath,
      );

  @override
  AppendImportResult crateApiSimpleAppendCbz({
    required String projectId,
    required String sourcePath,
  }) =>
      crateApiSimpleAppendArchive(
        projectId: projectId,
        format: ArchiveFormatFrb.cbz,
        sourcePath: sourcePath,
      );

  @override
  AppendImportResult crateApiSimpleAppendEpub({
    required String projectId,
    required String sourcePath,
  }) =>
      crateApiSimpleAppendArchive(
        projectId: projectId,
        format: ArchiveFormatFrb.epub,
        sourcePath: sourcePath,
      );

  @override
  List<String> crateApiSimpleArchiveFormatAllowedExtensions({
    required ArchiveFormatFrb format,
  }) =>
      _archiveExtensions[format] ?? const [];

  @override
  String crateApiSimpleArchiveFormatDisplayName({
    required ArchiveFormatFrb format,
  }) =>
      switch (format) {
        ArchiveFormatFrb.cbz => 'CBZ',
        ArchiveFormatFrb.cbr => 'CBR',
        ArchiveFormatFrb.cb7 => 'CB7',
        ArchiveFormatFrb.epub => 'EPUB',
      };

  @override
  ProjectSettings crateApiSimpleChangeProjectInferredImportKind({
    required String projectId,
    required InferredImportKindFrb inferredImportKind,
  }) =>
      _gateway.changeProjectInferredImportKind(
        projectId: projectId,
        inferredImportKind: inferredImportKind,
      );

  @override
  String crateApiExportComicArchiveContainerLabel({
    required ComicArchiveContainerFrb container,
  }) =>
      _comicArchiveContainerLabel(container);

  @override
  String crateApiExportComicArchiveFileExtension({
    required ProjectSettings settings,
  }) =>
      switch (settings.comicArchiveContainer) {
        ComicArchiveContainerFrb.zip =>
          settings.useComicArchiveExtension ? 'cbz' : 'zip',
        ComicArchiveContainerFrb.rar =>
          settings.useComicArchiveExtension ? 'cbr' : 'rar',
        ComicArchiveContainerFrb.sevenZip =>
          settings.useComicArchiveExtension ? 'cb7' : '7z',
      };

  @override
  List<String> crateApiSimpleComicArchivePickerExtensions() =>
      const ['cbz', 'zip', 'cbr', 'rar', 'cb7', '7z'];

  @override
  String crateApiSimpleCorePing() => 'Comic Book Maker Core connected (fake)';

  @override
  ProjectSummary crateApiSimpleCreateProject({String? title}) =>
      gateway.createProject(title: title);

  @override
  ProjectPageStructureFrb crateApiSimpleDeletePage({
    required String projectId,
    required String pageId,
  }) =>
      _toFrbStructure(
        _gateway.deletePage(projectId: projectId, pageId: pageId),
      );

  @override
  void crateApiSimpleDeleteProject({required String projectId}) =>
      _gateway.deleteProject(projectId: projectId);

  @override
  Future<void> crateApiSimpleExportCb7({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _export(
        projectId: projectId,
        destinationPath: destinationPath,
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Future<void> crateApiSimpleExportCbr({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _export(
        projectId: projectId,
        destinationPath: destinationPath,
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.rar,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Future<void> crateApiSimpleExportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _export(
        projectId: projectId,
        destinationPath: destinationPath,
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.zip,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Future<void> crateApiSimpleExportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _export(
        projectId: projectId,
        destinationPath: destinationPath,
        exportComicArchive: false,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  ExportFailurePresentationFrb crateApiExportExportErrorPresentation({
    required ExportError error,
  }) =>
      ExportFailurePresentationFrb(
        title: '无法导出',
        message: error.detail.isEmpty ? error.kind.name : error.detail,
      );

  @override
  Future<void> crateApiSimpleExportPdf({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _export(
        projectId: projectId,
        destinationPath: destinationPath,
        exportComicArchive: false,
        exportPdf: true,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  MetadataEditorSchemaFrb crateApiMetadataGetMetadataEditorSchema({
    required ExportFormatFrb exportFormat,
  }) =>
      _gateway.getMetadataEditorSchema(exportFormat: exportFormat);

  @override
  Metadata crateApiMetadataGetProjectMetadata({required String projectId}) =>
      _gateway.getProjectMetadata(projectId: projectId);

  @override
  ProjectSettings crateApiSimpleGetProjectSettings({required String projectId}) =>
      _gateway.getProjectSettings(projectId: projectId);

  @override
  String crateApiSimpleGreet({required String name}) => 'Hello, $name!';

  @override
  ImportCbzResult crateApiSimpleImportArchive({
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) =>
      _gateway.importArchive(format: format, sourcePath: sourcePath);

  @override
  ImportCbzResult crateApiSimpleImportCb7({required String sourcePath}) =>
      crateApiSimpleImportArchive(
        format: ArchiveFormatFrb.cb7,
        sourcePath: sourcePath,
      );

  @override
  ImportCbzResult crateApiSimpleImportCbr({required String sourcePath}) =>
      crateApiSimpleImportArchive(
        format: ArchiveFormatFrb.cbr,
        sourcePath: sourcePath,
      );

  @override
  ImportCbzResult crateApiSimpleImportCbz({required String sourcePath}) =>
      crateApiSimpleImportArchive(
        format: ArchiveFormatFrb.cbz,
        sourcePath: sourcePath,
      );

  @override
  ImportCbzResult crateApiSimpleImportEpub({required String sourcePath}) =>
      crateApiSimpleImportArchive(
        format: ArchiveFormatFrb.epub,
        sourcePath: sourcePath,
      );

  @override
  ArchiveFormatFrb? crateApiSimpleInferArchiveFormatFromPath({
    required String path,
  }) {
    final ext = _extension(path);
    for (final entry in _archiveExtensions.entries) {
      if (entry.value.contains(ext)) return entry.key;
    }
    return null;
  }

  @override
  ArchiveFormatFrb? crateApiSimpleInferComicArchiveFormatFromPath({
    required String path,
  }) {
    final ext = _extension(path);
    for (final entry in _comicArchiveExtensions.entries) {
      if (entry.value.contains(ext)) return entry.key;
    }
    return null;
  }

  @override
  Future<void> crateApiSimpleInitApp() async {}

  @override
  void crateApiSimpleInitLibrary({required String appDataDir}) {}

  @override
  void crateApiSimpleResetLibraryForTesting() {}

  @override
  bool crateApiExportIsComicArchiveContainerImplemented({
    required ComicArchiveContainerFrb container,
  }) =>
      true;

  @override
  bool crateApiExportIsComicArchiveContainerSelectable({
    required ComicArchiveContainerFrb container,
  }) =>
      true;

  @override
  List<PageSummary> crateApiSimpleListPages({required String projectId}) =>
      _gateway.listPages(projectId: projectId);

  @override
  List<ProjectSummary> crateApiSimpleListProjects() => _gateway.listProjects();

  @override
  ProjectPageStructureFrb crateApiSimpleLoadPageStructure({
    required String projectId,
  }) =>
      _toFrbStructure(_gateway.loadPageStructure(projectId: projectId));

  @override
  ProjectEditorSnapshotFrb crateApiSimpleLoadProjectEditorSnapshot({
    required String projectId,
  }) =>
      _toEditorSnapshot(
        _gateway.loadProjectEditorSnapshot(projectId: projectId),
      );

  @override
  Metadata crateApiMetadataMergeMetadataFromForm({
    required ExportFormatFrb exportFormat,
    required Metadata base,
    required List<MetadataFieldValueFrb> fieldValues,
    required int pageCount,
  }) =>
      _gateway.mergeMetadataFromForm(
        exportFormat: exportFormat,
        base: base,
        fieldValues: fieldValues,
        pageCount: pageCount,
      );

  @override
  Future<Metadata> crateApiMetadataMetadataDefault() async =>
      const Metadata(title: '未命名', coverPageIndex: 0, pageCount: 0);

  @override
  String crateApiMetadataMetadataFieldDisplayValue({
    required Metadata metadata,
    required String fieldId,
  }) =>
      _gateway.metadataFieldDisplayValue(metadata: metadata, fieldId: fieldId);

  @override
  Metadata crateApiMetadataMetadataWithCoverPageIndex({
    required Metadata metadata,
    required int coverPageIndex,
  }) =>
      _gateway.metadataWithCoverPageIndex(
        metadata: metadata,
        coverPageIndex: coverPageIndex,
      );

  @override
  Metadata crateApiMetadataMetadataWithDropdownField({
    required Metadata metadata,
    required String fieldId,
    String? value,
  }) =>
      _gateway.metadataWithDropdownField(
        metadata: metadata,
        fieldId: fieldId,
        value: value,
      );

  @override
  Metadata crateApiMetadataMetadataWithPageCount({
    required Metadata metadata,
    required int pageCount,
  }) =>
      _gateway.metadataWithPageCount(metadata: metadata, pageCount: pageCount);

  @override
  ExportPlanResultFrb crateApiExportPlanExport({
    required ExportPlanRequestFrb request,
  }) {
    throw UnsupportedError(
      'FakeRustLibApi does not implement planExport; use rust_integration',
    );
  }

  @override
  ProjectPageStructureFrb crateApiSimpleReorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) =>
      _toFrbStructure(
        _gateway.reorderPages(
          projectId: projectId,
          orderedPageIds: orderedPageIds,
        ),
      );

  @override
  ProjectPageStructureFrb crateApiSimpleReplacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) =>
      _toFrbStructure(
        _gateway.replacePageImage(
          projectId: projectId,
          pageId: pageId,
          sourcePath: sourcePath,
        ),
      );

  @override
  String crateApiExportSanitizeExportTitle({required String title}) =>
      title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  @override
  int crateApiSimpleSetCoverPage({
    required String projectId,
    required int coverPageIndex,
  }) =>
      _gateway.setProjectCoverPage(
        projectId: projectId,
        coverPageIndex: coverPageIndex,
      );

  @override
  void crateApiSimpleTouchProject({required String projectId}) =>
      _gateway.touchProject(projectId: projectId);

  @override
  ProjectSettings crateApiSimpleUpdateProjectExportFormat({
    required String projectId,
    required ExportFormatFrb exportFormat,
  }) {
    final current = _gateway.getProjectSettings(projectId: projectId);
    return _gateway.updateProjectSettings(
      projectId: projectId,
      update: ProjectSettingsUpdate(
        exportFormat: exportFormat,
        deleteProjectAfterExport: current.deleteProjectAfterExport,
        useDefaultExportDirectory: current.useDefaultExportDirectory,
        exportDirectory: current.exportDirectory,
        comicArchiveContainer: current.comicArchiveContainer,
        useComicArchiveExtension: current.useComicArchiveExtension,
      ),
    );
  }

  @override
  Metadata crateApiMetadataUpdateProjectMetadata({
    required String projectId,
    required Metadata metadata,
  }) =>
      _gateway.updateProjectMetadata(projectId: projectId, metadata: metadata);

  @override
  ProjectSettings crateApiSimpleUpdateProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  }) =>
      _gateway.updateProjectSettings(projectId: projectId, update: update);

  @override
  ProjectSummary crateApiSimpleUpdateProjectTitle({
    required String projectId,
    required String title,
  }) =>
      _gateway.updateProjectTitle(projectId: projectId, title: title);

  Future<void> _export({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    ComicArchiveContainerFrb? comicArchiveContainer,
    bool exportPdf = false,
    required bool deleteProjectAfterExport,
  }) =>
      _gateway.exportArchive(
        projectId: projectId,
        destinationPath: destinationPath,
        exportComicArchive: exportComicArchive,
        comicArchiveContainer: comicArchiveContainer,
        exportPdf: exportPdf,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );
}

String _extension(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final name = normalized.split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

String _comicArchiveContainerLabel(ComicArchiveContainerFrb container) =>
    switch (container) {
      ComicArchiveContainerFrb.zip => 'ZIP',
      ComicArchiveContainerFrb.sevenZip => '7Z',
      ComicArchiveContainerFrb.rar => 'RAR',
    };

const _archiveExtensions = {
  ArchiveFormatFrb.cbz: ['cbz', 'zip'],
  ArchiveFormatFrb.cbr: ['cbr', 'rar'],
  ArchiveFormatFrb.cb7: ['cb7', '7z'],
  ArchiveFormatFrb.epub: ['epub'],
};

const _comicArchiveExtensions = {
  ArchiveFormatFrb.cbz: ['cbz', 'zip'],
  ArchiveFormatFrb.cbr: ['cbr', 'rar'],
  ArchiveFormatFrb.cb7: ['cb7', '7z'],
};

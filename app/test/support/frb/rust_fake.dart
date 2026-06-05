import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';

import '../data/repositories/in_memory_core_gateway.dart';

export '../data/repositories/in_memory_core_gateway.dart'
    show InMemoryCoreGateway, kEmptyLibraryMetadata, kMetadataPanelFixture;

/// 将 [InMemoryCoreGateway] 适配为 FRB [`RustLibApi`]，供 widget / 仍直连 rust 的测试使用。
class FakeRustLibApi extends RustLibApi {
  FakeRustLibApi([InMemoryCoreGateway? gateway])
      : _gateway = gateway ?? InMemoryCoreGateway.emptyLibrary();

  final InMemoryCoreGateway _gateway;

  factory FakeRustLibApi.emptyLibrary() =>
      FakeRustLibApi(InMemoryCoreGateway.emptyLibrary());

  factory FakeRustLibApi.metadataPanel() =>
      FakeRustLibApi(InMemoryCoreGateway.metadataPanel());

  factory FakeRustLibApi.editorProject() =>
      FakeRustLibApi(InMemoryCoreGateway.editorProject());

  List<ProjectSummary> get projects => _gateway.projects;
  Map<String, Metadata> get metadataByProjectId => _gateway.metadataByProjectId;
  List<PageSummary> get pages => _gateway.pages;
  Metadata get defaultMetadata => _gateway.defaultMetadata;
  ProjectSettings get defaultSettings => _gateway.defaultSettings;
  set defaultSettings(ProjectSettings value) => _gateway.defaultSettings = value;
  Object? get nextMetadataUpdateError => _gateway.nextMetadataUpdateError;
  set nextMetadataUpdateError(Object? value) =>
      _gateway.nextMetadataUpdateError = value;
  bool get failMetadataUpdates => _gateway.failMetadataUpdates;
  set failMetadataUpdates(bool value) => _gateway.failMetadataUpdates = value;
  int get metadataUpdateCallCount => _gateway.metadataUpdateCallCount;
  set metadataUpdateCallCount(int value) =>
      _gateway.metadataUpdateCallCount = value;
  int get exportCallCount => _gateway.exportCallCount;
  set exportCallCount(int value) => _gateway.exportCallCount = value;
  void Function()? get onMetadataUpdate => _gateway.onMetadataUpdate;
  set onMetadataUpdate(void Function()? value) =>
      _gateway.onMetadataUpdate = value;

  @override
  String crateApiSimpleCorePing() => 'mock';

  @override
  String crateApiSimpleGreet({required String name}) => name;

  @override
  Future<void> crateApiSimpleInitApp() async {}

  @override
  void crateApiSimpleInitLibrary({required String appDataDir}) {}

  @override
  ProjectSummary crateApiSimpleCreateProject({String? title}) =>
      _gateway.createProject(title: title);

  @override
  List<ProjectSummary> crateApiSimpleListProjects() => _gateway.listProjects();

  @override
  void crateApiSimpleTouchProject({required String projectId}) =>
      _gateway.touchProject(projectId: projectId);

  @override
  void crateApiSimpleDeleteProject({required String projectId}) =>
      _gateway.deleteProject(projectId: projectId);

  @override
  List<PageSummary> crateApiSimpleListPages({required String projectId}) =>
      _gateway.listPages(projectId: projectId);

  @override
  List<PageSummary> crateApiSimpleAddPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) =>
      _gateway.addPageImages(
        projectId: projectId,
        sourcePaths: sourcePaths,
      );

  @override
  void crateApiSimpleDeletePage({
    required String projectId,
    required String pageId,
  }) =>
      _gateway.deletePage(projectId: projectId, pageId: pageId);

  @override
  PageSummary crateApiSimpleReplacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) =>
      _gateway.replacePageImage(
        projectId: projectId,
        pageId: pageId,
        sourcePath: sourcePath,
      );

  @override
  List<PageSummary> crateApiSimpleReorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) =>
      _gateway.reorderPages(
        projectId: projectId,
        orderedPageIds: orderedPageIds,
      );

  @override
  ProjectSettings crateApiSimpleGetProjectSettings({required String projectId}) =>
      _gateway.getProjectSettings(projectId: projectId);

  @override
  ProjectSettings crateApiSimpleUpdateProjectExportFormat({
    required String projectId,
    required ExportFormatFrb exportFormat,
  }) {
    final s = _gateway.defaultSettings;
    _gateway.defaultSettings = ProjectSettings(
      exportFormat: exportFormat,
      inferredImportKind: s.inferredImportKind,
      deleteProjectAfterExport: s.deleteProjectAfterExport,
      useDefaultExportDirectory: s.useDefaultExportDirectory,
      exportDirectory: s.exportDirectory,
      comicArchiveContainer: s.comicArchiveContainer,
      useComicArchiveExtension: s.useComicArchiveExtension,
    );
    return _gateway.defaultSettings;
  }

  @override
  ProjectSettings crateApiSimpleUpdateProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  }) =>
      _gateway.updateProjectSettings(
        projectId: projectId,
        update: update,
      );

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
  ImportMetadataSnapshotFrb crateApiSimpleGetImportMetadataSnapshot({
    required String projectId,
  }) =>
      _gateway.getImportMetadataSnapshot(projectId: projectId);

  @override
  AppendImportResult crateApiSimpleAppendCbz({
    required String projectId,
    required String sourcePath,
  }) =>
      _gateway.appendCbz(projectId: projectId, sourcePath: sourcePath);

  @override
  AppendImportResult crateApiSimpleAppendCbr({
    required String projectId,
    required String sourcePath,
  }) =>
      _gateway.appendCbr(projectId: projectId, sourcePath: sourcePath);

  @override
  AppendImportResult crateApiSimpleAppendEpub({
    required String projectId,
    required String sourcePath,
  }) =>
      _gateway.appendEpub(projectId: projectId, sourcePath: sourcePath);

  @override
  ImportCbzResult crateApiSimpleImportCbz({required String sourcePath}) =>
      _gateway.importCbz(sourcePath: sourcePath);

  @override
  ImportCbzResult crateApiSimpleImportCbr({required String sourcePath}) =>
      _gateway.importCbr(sourcePath: sourcePath);

  @override
  ImportCbzResult crateApiSimpleImportEpub({required String sourcePath}) =>
      _gateway.importEpub(sourcePath: sourcePath);

  @override
  Future<void> crateApiSimpleExportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _gateway.exportCbz(
        projectId: projectId,
        destinationPath: destinationPath,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Future<void> crateApiSimpleExportCbr({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _gateway.exportCbr(
        projectId: projectId,
        destinationPath: destinationPath,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Future<void> crateApiSimpleExportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) =>
      _gateway.exportEpub(
        projectId: projectId,
        destinationPath: destinationPath,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  @override
  Metadata crateApiMetadataGetProjectMetadata({required String projectId}) =>
      _gateway.getProjectMetadata(projectId: projectId);

  @override
  Metadata crateApiMetadataUpdateProjectMetadata({
    required String projectId,
    required Metadata metadata,
  }) =>
      _gateway.updateProjectMetadata(
        projectId: projectId,
        metadata: metadata,
      );

  @override
  Future<Metadata> crateApiMetadataMetadataDefault() async =>
      _gateway.defaultMetadata;

  @override
  Metadata crateApiMetadataMetadataWithPageCount({
    required Metadata metadata,
    required int pageCount,
  }) =>
      _gateway.metadataWithPageCount(metadata: metadata, pageCount: pageCount);

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
  MetadataEditorSchemaFrb crateApiMetadataGetMetadataEditorSchema({
    required ExportFormatFrb exportFormat,
  }) =>
      _gateway.getMetadataEditorSchema(exportFormat: exportFormat);

  @override
  String crateApiMetadataMetadataFieldDisplayValue({
    required Metadata metadata,
    required String fieldId,
  }) =>
      _gateway.metadataFieldDisplayValue(metadata: metadata, fieldId: fieldId);

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
}

/// 安装 FRB mock；每个测试文件在 `setUp` / `setUpAll` 中调用一次。
void initRustTestFake([FakeRustLibApi? fake]) {
  RustLib.initMock(api: fake ?? FakeRustLibApi.emptyLibrary());
}

import 'package:comic_book_maker/application/core_gateway.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';

import 'metadata_clone.dart';
import 'metadata_editor_schema.dart';

/// 默认空库元数据（`widget_test` 等）。
const Metadata kEmptyLibraryMetadata = Metadata(
  title: '未命名',
  coverPageIndex: 0,
  pageCount: 0,
);

/// `MetadataPanel` widget 测试用的预置元数据（projectId `p1`）。
const Metadata kMetadataPanelFixture = Metadata(
  title: '初始标题',
  series: '初始系列',
  issueNumber: '01',
  volume: '1',
  summary: '简介',
  writer: '作者',
  publisher: '出版社',
  languageIso: 'zh-CN',
  gtin: '123',
  coverPageIndex: 0,
  pageCount: 3,
);

/// 测试用 in-memory [CoreGateway]；状态与工厂替代臃肿的 FRB mock 实现。
class InMemoryCoreGateway implements CoreGateway {
  InMemoryCoreGateway({
    List<ProjectSummary>? projects,
    Map<String, Metadata>? metadataByProjectId,
    this.defaultMetadata = kEmptyLibraryMetadata,
    ProjectSettings? defaultSettings,
    this.nextMetadataUpdateError,
    List<PageSummary>? pages,
  })  : projects = List.of(projects ?? []),
        metadataByProjectId = Map.of(metadataByProjectId ?? {}),
        pages = List.of(pages ?? []),
        defaultSettings = defaultSettings ??
            const ProjectSettings(
              exportFormat: ExportFormatFrb.comicArchive,
              inferredImportKind: InferredImportKindFrb.images,
              deleteProjectAfterExport: false,
              useDefaultExportDirectory: true,
              exportDirectory: null,
              comicArchiveContainer: ComicArchiveContainerFrb.zip,
              useComicArchiveExtension: true,
            );

  factory InMemoryCoreGateway.emptyLibrary() => InMemoryCoreGateway();

  factory InMemoryCoreGateway.metadataPanel() => InMemoryCoreGateway(
        metadataByProjectId: const {'p1': kMetadataPanelFixture},
      );

  static PageSummary get _editorPage => PageSummary(
        id: 'page-1',
        sortIndex: 0,
        assetPath: 'assets/page-1.png',
        absolutePath: r'C:\temp\page-1.png',
      );

  factory InMemoryCoreGateway.editorProject() {
    final project = ProjectSummary(
      id: 'p1',
      title: '测试项目',
      updatedAtMs: DateTime.utc(2024, 1, 1).millisecondsSinceEpoch,
      coverThumbnailPath: null,
    );
    return InMemoryCoreGateway(
      projects: [project],
      metadataByProjectId: const {
        'p1': Metadata(
          title: '初始标题',
          series: '初始系列',
          issueNumber: '01',
          volume: '1',
          summary: '简介',
          writer: '作者',
          publisher: '出版社',
          languageIso: 'zh-CN',
          gtin: '123',
          coverPageIndex: 0,
          pageCount: 1,
        ),
      },
      pages: [_editorPage],
      defaultSettings: const ProjectSettings(
        exportFormat: ExportFormatFrb.comicArchive,
        inferredImportKind: InferredImportKindFrb.images,
        deleteProjectAfterExport: false,
        useDefaultExportDirectory: false,
        exportDirectory: r'C:\temp\comic-exports',
        comicArchiveContainer: ComicArchiveContainerFrb.zip,
        useComicArchiveExtension: true,
      ),
    );
  }

  final List<ProjectSummary> projects;
  final Map<String, Metadata> metadataByProjectId;
  final List<PageSummary> pages;
  final Metadata defaultMetadata;
  ProjectSettings defaultSettings;
  Object? nextMetadataUpdateError;
  bool failMetadataUpdates = false;
  int metadataUpdateCallCount = 0;
  void Function()? onMetadataUpdate;

  Metadata metadataFor(String projectId) =>
      metadataByProjectId[projectId] ?? defaultMetadata;

  @override
  List<ProjectSummary> listProjects() => List.of(projects);

  @override
  void touchProject({required String projectId}) {}

  @override
  void deleteProject({required String projectId}) {
    projects.removeWhere((p) => p.id == projectId);
    metadataByProjectId.remove(projectId);
  }

  @override
  ProjectSummary createProject({String? title}) {
    final project = ProjectSummary(
      id: 'project-${projects.length + 1}',
      title: title ?? '未命名',
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      coverThumbnailPath: null,
    );
    projects.add(project);
    return project;
  }

  @override
  ImportCbzResult importCbz({required String sourcePath}) => _importArchive();

  @override
  ImportCbzResult importCbr({required String sourcePath}) => _importArchive();

  @override
  ImportCbzResult importEpub({required String sourcePath}) => _importArchive();

  ImportCbzResult _importArchive() => ImportCbzResult(
        project: ProjectSummary(
          id: 'imported-1',
          title: 'Imported',
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          coverThumbnailPath: null,
        ),
        warnings: const [],
      );

  @override
  List<PageSummary> addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) =>
      [];

  @override
  ProjectSettings getProjectSettings({required String projectId}) =>
      defaultSettings;

  @override
  ProjectSettings updateProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  }) {
    defaultSettings = ProjectSettings(
      exportFormat: update.exportFormat,
      inferredImportKind: defaultSettings.inferredImportKind,
      deleteProjectAfterExport: update.deleteProjectAfterExport,
      useDefaultExportDirectory: update.useDefaultExportDirectory,
      exportDirectory: update.exportDirectory,
      comicArchiveContainer: update.comicArchiveContainer,
      useComicArchiveExtension: update.useComicArchiveExtension,
    );
    return defaultSettings;
  }

  @override
  Metadata getProjectMetadata({required String projectId}) =>
      metadataFor(projectId);

  @override
  Metadata updateProjectMetadata({
    required String projectId,
    required Metadata metadata,
  }) {
    metadataUpdateCallCount++;
    if (failMetadataUpdates) {
      throw Exception('磁盘写入失败');
    }
    if (nextMetadataUpdateError != null) {
      final error = nextMetadataUpdateError!;
      nextMetadataUpdateError = null;
      if (error is Exception) throw error;
      throw Exception(error.toString());
    }
    onMetadataUpdate?.call();
    metadataByProjectId[projectId] = metadata;
    return metadata;
  }

  @override
  ImportMetadataSnapshotFrb getImportMetadataSnapshot({
    required String projectId,
  }) =>
      const ImportMetadataSnapshotFrb(
        kind: ImportMetadataKindFrb.none,
        xml: null,
      );

  @override
  MetadataEditorSchemaFrb getMetadataEditorSchema({
    required ExportFormatFrb exportFormat,
  }) =>
      metadataEditorSchemaFixture(exportFormat);

  @override
  Metadata metadataWithPageCount({
    required Metadata metadata,
    required int pageCount,
  }) =>
      mockMetadataWithPageCount(metadata: metadata, pageCount: pageCount);

  @override
  Metadata metadataWithDropdownField({
    required Metadata metadata,
    required String fieldId,
    String? value,
  }) =>
      mockMetadataWithDropdownField(
        metadata: metadata,
        fieldId: fieldId,
        value: value,
      );

  @override
  Metadata metadataWithCoverPageIndex({
    required Metadata metadata,
    required int coverPageIndex,
  }) =>
      mockMetadataWithCoverPageIndex(
        metadata: metadata,
        coverPageIndex: coverPageIndex,
      );

  @override
  String metadataFieldDisplayValue({
    required Metadata metadata,
    required String fieldId,
  }) =>
      mockMetadataFieldDisplayValue(metadata: metadata, fieldId: fieldId);

  @override
  Metadata mergeMetadataFromForm({
    required ExportFormatFrb exportFormat,
    required Metadata base,
    required List<MetadataFieldValueFrb> fieldValues,
    required int pageCount,
  }) =>
      mockMergeMetadataFromForm(
        base: base,
        fieldValues: fieldValues,
        pageCount: pageCount,
      );

  @override
  ProjectSettings changeProjectInferredImportKind({
    required String projectId,
    required InferredImportKindFrb inferredImportKind,
  }) {
    defaultSettings = ProjectSettings(
      exportFormat: defaultSettings.exportFormat,
      inferredImportKind: inferredImportKind,
      deleteProjectAfterExport: defaultSettings.deleteProjectAfterExport,
      useDefaultExportDirectory: defaultSettings.useDefaultExportDirectory,
      exportDirectory: defaultSettings.exportDirectory,
      comicArchiveContainer: defaultSettings.comicArchiveContainer,
      useComicArchiveExtension: defaultSettings.useComicArchiveExtension,
    );
    return defaultSettings;
  }

  @override
  List<PageSummary> listPages({required String projectId}) => List.of(pages);

  @override
  AppendImportResult appendCbz({
    required String projectId,
    required String sourcePath,
  }) =>
      const AppendImportResult(warnings: [], addedPageCount: 0);

  @override
  AppendImportResult appendCbr({
    required String projectId,
    required String sourcePath,
  }) =>
      const AppendImportResult(warnings: [], addedPageCount: 0);

  @override
  AppendImportResult appendEpub({
    required String projectId,
    required String sourcePath,
  }) =>
      const AppendImportResult(warnings: [], addedPageCount: 0);

  @override
  void deletePage({required String projectId, required String pageId}) {}

  @override
  PageSummary replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) =>
      PageSummary(
        id: pageId,
        sortIndex: 0,
        assetPath: 'assets/$pageId.png',
        absolutePath: '/tmp/$pageId.png',
      );

  @override
  List<PageSummary> reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) =>
      [];

  @override
  Future<void> exportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {}

  @override
  Future<void> exportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {}
}

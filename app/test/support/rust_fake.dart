import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';

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

/// 实现全部 [`RustLibApi`] 的 in-memory fake，供 widget / integration 测试共用。
class FakeRustLibApi extends RustLibApi {
  FakeRustLibApi({
    List<ProjectSummary>? projects,
    Map<String, Metadata>? metadataByProjectId,
    this.defaultMetadata = kEmptyLibraryMetadata,
    this.defaultSettings = const ProjectSettings(
      exportFormat: ExportFormatFrb.comicArchive,
      inferredImportKind: InferredImportKindFrb.images,
      deleteProjectAfterExport: false,
      useDefaultExportDirectory: true,
      exportDirectory: null,
      comicArchiveContainer: ComicArchiveContainerFrb.zip,
      useComicArchiveExtension: true,
    ),
    this.nextMetadataUpdateError,
    List<PageSummary>? pages,
  })  : projects = List.of(projects ?? []),
        metadataByProjectId = Map.of(metadataByProjectId ?? {}),
        pages = List.of(pages ?? []);

  /// 空漫画库（无项目）。
  factory FakeRustLibApi.emptyLibrary() => FakeRustLibApi();

  /// 元数据面板测试：`p1` 带 fixture 元数据。
  factory FakeRustLibApi.metadataPanel() => FakeRustLibApi(
        metadataByProjectId: const {'p1': kMetadataPanelFixture},
      );

  static PageSummary get _editorPage => PageSummary(
        id: 'page-1',
        sortIndex: 0,
        assetPath: 'assets/page-1.png',
        absolutePath: r'C:\temp\page-1.png',
      );

  /// 项目编辑页：库内一个项目 + 元数据 fixture + 可导出设置。
  factory FakeRustLibApi.editorProject() {
    final project = ProjectSummary(
      id: 'p1',
      title: '测试项目',
      updatedAtMs: DateTime.utc(2024, 1, 1).millisecondsSinceEpoch,
      coverThumbnailPath: null,
    );
    return FakeRustLibApi(
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
  String crateApiSimpleCorePing() => 'mock';

  @override
  String crateApiSimpleGreet({required String name}) => name;

  @override
  Future<void> crateApiSimpleInitApp() async {}

  @override
  void crateApiSimpleInitLibrary({required String appDataDir}) {}

  @override
  ProjectSummary crateApiSimpleCreateProject({String? title}) {
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
  List<ProjectSummary> crateApiSimpleListProjects() => List.of(projects);

  @override
  void crateApiSimpleTouchProject({required String projectId}) {}

  @override
  void crateApiSimpleDeleteProject({required String projectId}) {
    projects.removeWhere((p) => p.id == projectId);
    metadataByProjectId.remove(projectId);
  }

  @override
  List<PageSummary> crateApiSimpleListPages({required String projectId}) =>
      List.of(pages);

  @override
  List<PageSummary> crateApiSimpleAddPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) =>
      [];

  @override
  void crateApiSimpleDeletePage({
    required String projectId,
    required String pageId,
  }) {}

  @override
  PageSummary crateApiSimpleReplacePageImage({
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
  List<PageSummary> crateApiSimpleReorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) =>
      [];

  @override
  ProjectSettings crateApiSimpleGetProjectSettings({required String projectId}) =>
      defaultSettings;

  @override
  ProjectSettings crateApiSimpleUpdateProjectExportFormat({
    required String projectId,
    required ExportFormatFrb exportFormat,
  }) =>
      ProjectSettings(
        exportFormat: exportFormat,
        inferredImportKind: defaultSettings.inferredImportKind,
        deleteProjectAfterExport: defaultSettings.deleteProjectAfterExport,
        useDefaultExportDirectory: defaultSettings.useDefaultExportDirectory,
        exportDirectory: defaultSettings.exportDirectory,
        comicArchiveContainer: defaultSettings.comicArchiveContainer,
        useComicArchiveExtension: defaultSettings.useComicArchiveExtension,
      );

  @override
  ProjectSettings crateApiSimpleUpdateProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  }) =>
      ProjectSettings(
        exportFormat: update.exportFormat,
        inferredImportKind: defaultSettings.inferredImportKind,
        deleteProjectAfterExport: update.deleteProjectAfterExport,
        useDefaultExportDirectory: update.useDefaultExportDirectory,
        exportDirectory: update.exportDirectory,
        comicArchiveContainer: update.comicArchiveContainer,
        useComicArchiveExtension: update.useComicArchiveExtension,
      );

  @override
  ProjectSettings crateApiSimpleChangeProjectInferredImportKind({
    required String projectId,
    required InferredImportKindFrb inferredImportKind,
  }) =>
      ProjectSettings(
        exportFormat: defaultSettings.exportFormat,
        inferredImportKind: inferredImportKind,
        deleteProjectAfterExport: defaultSettings.deleteProjectAfterExport,
        useDefaultExportDirectory: defaultSettings.useDefaultExportDirectory,
        exportDirectory: defaultSettings.exportDirectory,
        comicArchiveContainer: defaultSettings.comicArchiveContainer,
        useComicArchiveExtension: defaultSettings.useComicArchiveExtension,
      );

  @override
  ImportMetadataSnapshotFrb crateApiSimpleGetImportMetadataSnapshot({
    required String projectId,
  }) =>
      const ImportMetadataSnapshotFrb(
        kind: ImportMetadataKindFrb.none,
        xml: null,
      );

  @override
  AppendImportResult crateApiSimpleAppendCbz({
    required String projectId,
    required String sourcePath,
  }) =>
      const AppendImportResult(warnings: [], addedPageCount: 0);

  @override
  AppendImportResult crateApiSimpleAppendCbr({
    required String projectId,
    required String sourcePath,
  }) =>
      const AppendImportResult(warnings: [], addedPageCount: 0);

  @override
  AppendImportResult crateApiSimpleAppendEpub({
    required String projectId,
    required String sourcePath,
  }) =>
      const AppendImportResult(warnings: [], addedPageCount: 0);

  @override
  ImportCbzResult crateApiSimpleImportCbz({required String sourcePath}) =>
      ImportCbzResult(
        project: ProjectSummary(
          id: 'imported-1',
          title: 'Imported',
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          coverThumbnailPath: null,
        ),
        warnings: const [],
      );

  @override
  ImportCbzResult crateApiSimpleImportCbr({required String sourcePath}) =>
      crateApiSimpleImportCbz(sourcePath: sourcePath);

  @override
  ImportCbzResult crateApiSimpleImportEpub({required String sourcePath}) =>
      crateApiSimpleImportCbz(sourcePath: sourcePath);

  @override
  Future<void> crateApiSimpleExportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {}

  @override
  Future<void> crateApiSimpleExportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {}

  @override
  Metadata crateApiMetadataGetProjectMetadata({required String projectId}) =>
      metadataFor(projectId);

  @override
  Metadata crateApiMetadataUpdateProjectMetadata({
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
  Future<Metadata> crateApiMetadataMetadataDefault() async => defaultMetadata;

  @override
  Metadata crateApiMetadataMetadataWithPageCount({
    required Metadata metadata,
    required int pageCount,
  }) =>
      mockMetadataWithPageCount(metadata: metadata, pageCount: pageCount);

  @override
  Metadata crateApiMetadataMetadataWithCoverPageIndex({
    required Metadata metadata,
    required int coverPageIndex,
  }) =>
      mockMetadataWithCoverPageIndex(
        metadata: metadata,
        coverPageIndex: coverPageIndex,
      );

  @override
  Metadata crateApiMetadataMetadataWithDropdownField({
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
  MetadataEditorSchemaFrb crateApiMetadataGetMetadataEditorSchema({
    required ExportFormatFrb exportFormat,
  }) =>
      metadataEditorSchemaFixture(exportFormat);

  @override
  String crateApiMetadataMetadataFieldDisplayValue({
    required Metadata metadata,
    required String fieldId,
  }) =>
      mockMetadataFieldDisplayValue(metadata: metadata, fieldId: fieldId);

  @override
  Metadata crateApiMetadataMergeMetadataFromForm({
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
}

/// 安装 FRB mock；每个测试文件在 `setUp` / `setUpAll` 中调用一次。
void initRustTestFake([FakeRustLibApi? fake]) {
  RustLib.initMock(api: fake ?? FakeRustLibApi.emptyLibrary());
}

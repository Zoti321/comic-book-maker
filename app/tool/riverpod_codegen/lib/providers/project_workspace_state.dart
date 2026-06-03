import 'package:comic_book_maker/src/rust/api/simple.dart';

/// 项目编辑工作区的只读快照；变更经 [ProjectWorkspace] 提交到 Core。
class ProjectWorkspaceState {
  const ProjectWorkspaceState({
    required this.project,
    this.pages = const [],
    this.settings,
    this.coverPageIndex = 0,
    this.error,
    this.exporting = false,
    this.appendingImport = false,
    this.savingExportFormat = false,
    this.initialized = false,
  });

  final ProjectSummary project;
  final List<PageSummary> pages;
  final ProjectSettings? settings;
  final int coverPageIndex;
  final String? error;
  final bool exporting;
  final bool appendingImport;
  final bool savingExportFormat;
  final bool initialized;

  String get projectId => project.id;

  bool get canAppendImport =>
      settings != null &&
      !appendingImport &&
      !exporting &&
      !savingExportFormat &&
      settings!.inferredImportKind != InferredImportKindFrb.pdf;

  bool get canExport =>
      settings != null &&
      !exporting &&
      !savingExportFormat &&
      settings!.exportFormat != ExportFormatFrb.pdf;

  ProjectWorkspaceState copyWith({
    ProjectSummary? project,
    List<PageSummary>? pages,
    ProjectSettings? settings,
    int? coverPageIndex,
    String? error,
    bool clearError = false,
    bool? exporting,
    bool? appendingImport,
    bool? savingExportFormat,
    bool? initialized,
  }) {
    return ProjectWorkspaceState(
      project: project ?? this.project,
      pages: pages ?? this.pages,
      settings: settings ?? this.settings,
      coverPageIndex: coverPageIndex ?? this.coverPageIndex,
      error: clearError ? null : (error ?? this.error),
      exporting: exporting ?? this.exporting,
      appendingImport: appendingImport ?? this.appendingImport,
      savingExportFormat: savingExportFormat ?? this.savingExportFormat,
      initialized: initialized ?? this.initialized,
    );
  }

  static ProjectWorkspaceState uninitialized(String projectId) {
    return ProjectWorkspaceState(
      project: ProjectSummary(
        id: projectId,
        title: '',
        updatedAtMs: 0,
        coverThumbnailPath: null,
      ),
    );
  }
}

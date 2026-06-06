import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';

/// 项目编辑工作区的只读快照；变更经 [ProjectWorkspace] 与 [ProjectEditingSession] 提交到 Core。
class ProjectWorkspaceState {
  const ProjectWorkspaceState({
    required this.project,
    this.pages = const [],
    this.settings,
    this.coverPageIndex = 0,
    this.error,
    this.appendingImport = false,
    this.savingExportFormat = false,
    this.initialized = false,
  });

  final ProjectSummary project;
  final List<PageSummary> pages;
  final ProjectSettings? settings;
  final int coverPageIndex;
  final String? error;
  final bool appendingImport;
  final bool savingExportFormat;
  final bool initialized;

  String get projectId => project.id;

  bool get canAppendImport => canAppendImportForSettings(
        settings,
        operationInProgress: appendingImport || savingExportFormat,
      );

  bool get canExport => canExportProject(
        settings: settings,
        pageCount: pages.length,
        operationInProgress: savingExportFormat,
      );

  ProjectWorkspaceState copyWith({
    ProjectSummary? project,
    List<PageSummary>? pages,
    ProjectSettings? settings,
    int? coverPageIndex,
    String? error,
    bool clearError = false,
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

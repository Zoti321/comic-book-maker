import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 项目编辑路由页：从 URL [projectId] 解析 [ProjectSummary]。
///
/// [GoRouter] 在布局变化时会重跑 [pageBuilder]，`state.extra` 不会保留；
/// 因此不能仅依赖导航时传入的 [initialProject]。
class ProjectEditorRoutePage extends ConsumerWidget {
  const ProjectEditorRoutePage({
    super.key,
    required this.projectId,
    this.initialProject,
  });

  final String projectId;
  final ProjectSummary? initialProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromExtra = initialProject;
    if (fromExtra != null && fromExtra.id == projectId) {
      return ProjectEditorPage(project: fromExtra);
    }

    final projects = ref.watch(libraryProjectsProvider);
    for (final project in projects) {
      if (project.id == projectId) {
        return ProjectEditorPage(project: project);
      }
    }

    return const Scaffold(
      body: Center(child: Text('缺少项目信息')),
    );
  }
}

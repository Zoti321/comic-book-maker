import 'package:comic_book_maker/ui/features/project_editor/pages/pages_panel.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_operations_flow.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 项目编辑页图片 Tab：仅订阅 [pages] 与 [coverPageIndex]，避免 workspace 其他字段变化重建网格。
class ProjectEditorImagesTab extends ConsumerWidget {
  const ProjectEditorImagesTab({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (pages, coverPageIndex) = ref.watch(
      projectWorkspaceProvider(projectId).select(
        (workspace) => (workspace.pages, workspace.coverPageIndex),
      ),
    );
    final workspaceNotifier =
        ref.read(projectWorkspaceProvider(projectId).notifier);

    return PageThumbnailGrid(
      pages: pages,
      coverPageIndex: coverPageIndex,
      onAdd: () => runGalleryAddPageImages(
        context: context,
        workspaceNotifier: workspaceNotifier,
      ),
      onReplace: (page) {
        final workspace = ref.read(projectWorkspaceProvider(projectId));
        runReplacePageImage(
          context: context,
          workspace: workspace,
          workspaceNotifier: workspaceNotifier,
          page: page,
        );
      },
      onDelete: (page) => runDeletePage(
        context: context,
        workspaceNotifier: workspaceNotifier,
        page: page,
      ),
      onSetCover: (page) => runSetCoverPage(
        context: context,
        workspaceNotifier: workspaceNotifier,
        page: page,
      ),
      onViewOriginal: (page) => runViewPageOriginal(
        context: context,
        pages: pages,
        page: page,
      ),
      onMoveEarlier: (page) => runMovePageEarlier(
        context: context,
        workspaceNotifier: workspaceNotifier,
        page: page,
      ),
      onMoveLater: (page) => runMovePageLater(
        context: context,
        workspaceNotifier: workspaceNotifier,
        page: page,
      ),
    );
  }
}

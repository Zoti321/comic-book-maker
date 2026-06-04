import 'package:comic_book_maker/application/library_operations.dart';
import 'package:comic_book_maker/providers/library_provider.dart';
import 'package:comic_book_maker/router/app_routes.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/create_project/create_project_wizard_flow.dart';
import 'package:comic_book_maker/ui/layout/responsive.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/theme/app_theme.dart';
import 'package:comic_book_maker/ui/widgets/page_header.dart';
import 'package:comic_book_maker/ui/widgets/project_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(libraryProjectsProvider);
    final library = ref.read(libraryOperationsProvider);
    final error = useState<String?>(null);

    Future<void> openProject(ProjectSummary project) async {
      try {
        library.recordProjectOpened(projectId: project.id);
        if (!context.mounted) return;
        await context.push(
          AppRoutes.projectEditorPath(project.id),
          extra: project,
        );
      } catch (e) {
        error.value = e.toString();
      }
    }

    Future<void> startCreateProject() async {
      error.value = null;

      try {
        await runCreateProjectWizard(
          context: context,
          library: library,
        );
      } catch (e) {
        if (!context.mounted) return;
        error.value = e.toString();
      }
    }

    Future<void> confirmDeleteProject(ProjectSummary project) async {
      final confirmed = await showAppConfirmDialog(
        context: context,
        title: '删除项目',
        description: Text(
          '确定删除「${project.title}」？\n本地页面与元数据将被永久删除，此操作不可恢复。',
        ),
        confirmLabel: '删除',
        destructive: true,
      );

      if (confirmed != true || !context.mounted) return;

      try {
        library.removeProject(projectId: project.id);
      } catch (e) {
        error.value = e.toString();
      }
    }

    final columns = libraryGridColumns(context);
    final padding = AppSpacing.pagePadding(context);
    final subtitle = projects.isEmpty
        ? null
        : '${projects.length} 个项目 · 按最近打开排序';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: '漫画库',
            subtitle: subtitle,
            actions: [
              AppButton(
                onPressed: startCreateProject,
                icon: const Icon(Icons.add),
                child: const Text('新建项目'),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        if (error.value != null)
          SliverToBoxAdapter(
            child: AppInlineErrorBanner(
              message: error.value!,
              onDismiss: () => error.value = null,
            ),
          ),
        SliverPadding(
          padding: padding,
          sliver: projects.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.collections_bookmark_outlined,
                    title: '还没有项目',
                    subtitle: '通过新建项目向导导入图片或漫画包开始制作',
                    action: AppButton(
                      onPressed: startCreateProject,
                      icon: const Icon(Icons.add),
                      child: const Text('新建项目'),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: libraryGridChildAspectRatio(context),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        title: project.title,
                        coverThumbnailPath: project.coverThumbnailPath,
                        updatedAt: DateTime.fromMillisecondsSinceEpoch(
                          project.updatedAtMs.toInt(),
                        ),
                        activityLabel: '最近打开',
                        onTap: () => openProject(project),
                        onDelete: () => confirmDeleteProject(project),
                      );
                    },
                    childCount: projects.length,
                  ),
                ),
        ),
      ],
    );
  }
}

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/page_header.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_flow.dart';
import 'package:comic_book_maker/ui/features/library/library_count_chip.dart';
import 'package:comic_book_maker/ui/features/library/library_empty_state.dart';
import 'package:comic_book_maker/ui/features/library/library_grid_layout.dart';
import 'package:comic_book_maker/ui/features/library/library_inline_error_banner.dart';
import 'package:comic_book_maker/ui/features/library/library_sort_menu_button.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_sort_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(sortedLibraryProjectsProvider);
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('删除项目'),
          content: Text(
            '确定删除「${project.title}」？\n本地页面与元数据将被永久删除，此操作不可恢复。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      try {
        library.removeProject(projectId: project.id);
      } catch (e) {
        error.value = e.toString();
      }
    }

    final columns = libraryGridColumns(context);
    final padding = libraryContentPadding(context);
    final compact = isCompact(context);

    final createButton = FilledButton.icon(
      onPressed: startCreateProject,
      style: libraryCompactFilledButtonStyle(context),
      icon: const Icon(LucideIcons.plus, size: 16),
      label: Text(compact ? '新建' : '新建项目'),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: '漫画库',
            titleTrailing: LibraryCountChip(count: projects.length),
            actions: [
              const LibrarySortMenuButton(),
              createButton,
            ],
          ),
        ),
        if (error.value != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              AppSpacing.sm,
              padding.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: LibraryInlineErrorBanner(
                message: error.value!,
                onDismiss: () => error.value = null,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        SliverPadding(
          padding: padding,
          sliver: projects.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: LibraryEmptyState(
                    onCreateProject: startCreateProject,
                    showAction: TickerMode.of(context),
                  ),
                )
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: libraryGridSpacing,
                    crossAxisSpacing: libraryGridSpacing,
                    childAspectRatio: libraryGridChildAspectRatio(context),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        title: project.title,
                        coverThumbnailPath: project.coverThumbnailPath,
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

import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_panel.dart';
import 'package:comic_book_maker/ui/features/project_editor/pages/pages_panel.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_append_flow.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_app_bar.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_export_flow.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_operations_flow.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_tab_switcher.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_dialog.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProjectEditorPage extends HookConsumerWidget {
  const ProjectEditorPage({super.key, required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(projectWorkspaceProvider(project.id));
    final workspaceNotifier =
        ref.read(projectWorkspaceProvider(project.id).notifier);

    final selectedTab = useState(ProjectEditorTab.images);
    final metadataController = useMemoized(MetadataPanelController.new);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(projectWorkspaceProvider(project.id).notifier)
            .initialize(project);
      });
      return null;
    }, [project.id]);

    Future<void> runExport() => runProjectExport(
          context: context,
          ref: ref,
          workspace: workspace,
          projectId: project.id,
          workspaceNotifier: workspaceNotifier,
          prepareMetadataForExport: metadataController.prepareForNavigation,
        );

    Future<void> appendFromSource() => runProjectAppendImport(
          context: context,
          workspace: workspace,
          workspaceNotifier: workspaceNotifier,
        );

    Widget imagesTabContent() {
      return PageThumbnailGrid(
        pages: workspace.pages,
        coverPageIndex: workspace.coverPageIndex,
        onAdd: () => runGalleryAddPageImages(
          context: context,
          workspaceNotifier: workspaceNotifier,
        ),
        onReplace: (page) => runReplacePageImage(
          context: context,
          workspace: workspace,
          workspaceNotifier: workspaceNotifier,
          page: page,
        ),
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

    Widget metadataTabContent() {
      final exportFormat =
          workspace.settings?.exportFormat ?? ExportFormatFrb.comicArchive;
      return MetadataPanel(
        key: ValueKey(exportFormat),
        projectId: workspace.projectId,
        pageCount: workspace.pages.length,
        exportFormat: exportFormat,
        controller: metadataController,
        onSaved: workspaceNotifier.applyMetadataSaved,
      );
    }

    Future<bool> leaveMetadataTabIfNeeded() async {
      if (selectedTab.value != ProjectEditorTab.metadata) return true;
      return metadataController.prepareForNavigation();
    }

    Future<void> selectTab(ProjectEditorTab tab) async {
      if (tab == selectedTab.value) return;
      if (!await leaveMetadataTabIfNeeded()) return;
      if (!context.mounted) return;
      selectedTab.value = tab;
    }

    Future<void> onBackPressed() async {
      if (!await leaveMetadataTabIfNeeded()) return;
      if (!context.mounted) return;
      context.pop();
    }

    void openProjectProperties() {
      showProjectPropertiesDialog(
        context: context,
        projectId: project.id,
      );
    }

    if (!workspace.initialized) {
      return const Scaffold(
        body: AppPageLoading(message: '正在加载项目…'),
      );
    }

    final pagePadding = AppSpacing.pagePadding(context);

    return PopScope(
      canPop: selectedTab.value != ProjectEditorTab.metadata,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await onBackPressed();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: ProjectEditorAppBar.toolbarPreferredSize,
          child: ProjectEditorAppBar(
            workspace: workspace,
            onExport: runExport,
            onAppendImport: appendFromSource,
            onBack: onBackPressed,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (workspace.error != null)
              AppInlineErrorBanner(
                message: workspace.error!,
                onDismiss: workspaceNotifier.clearError,
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding.left,
                  8,
                  pagePadding.right,
                  pagePadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProjectEditorTabSwitcher(
                      selectedTab: selectedTab.value,
                      onTabSelected: selectTab,
                      trailing: AppIconButton(
                        tooltip: '项目属性',
                        onPressed: openProjectProperties,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: IndexedStack(
                        index: selectedTab.value.index,
                        children: [
                          imagesTabContent(),
                          metadataTabContent(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

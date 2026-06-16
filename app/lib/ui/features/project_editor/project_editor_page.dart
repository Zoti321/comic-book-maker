import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_panel.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_images_tab.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_append_flow.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_app_bar.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_export_flow.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_inline_error_banner.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_states.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_tab_switcher.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_dialog.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
          gateway: ref.read(coreGatewayProvider),
        );

    Widget imagesTabContent() {
      return ProjectEditorImagesTab(projectId: project.id);
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
        body: ProjectEditorPageLoading(message: '正在加载项目…'),
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding.left,
                  AppSpacing.sm,
                  pagePadding.right,
                  0,
                ),
                child: ProjectEditorInlineErrorBanner(
                  message: workspace.error!,
                  onDismiss: workspaceNotifier.clearError,
                  padding: EdgeInsets.zero,
                ),
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
                      trailing: IconButton(
                        tooltip: '项目属性',
                        onPressed: openProjectProperties,
                        icon: const Icon(LucideIcons.settings),
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

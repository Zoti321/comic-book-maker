import 'package:comic_book_maker/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/metadata_panel.dart';
import 'package:comic_book_maker/ui/pages/pages_panel.dart';
import 'package:comic_book_maker/ui/import_kind_picker_rules.dart';
import 'package:comic_book_maker/ui/project_editor_append_flow.dart';
import 'package:comic_book_maker/ui/project_editor_app_bar.dart';
import 'package:comic_book_maker/ui/project_editor_export_flow.dart';
import 'package:comic_book_maker/ui/metadata_unsaved_guard.dart';
import 'package:comic_book_maker/ui/project_editor_tab_switcher.dart';
import 'package:comic_book_maker/ui/project_properties_dialog.dart';
import 'package:comic_book_maker/ui/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
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
    final metadataDirty = useState(false);
    final metadataDiscardGeneration = useState(0);

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
          workspaceNotifier: workspaceNotifier,
        );

    Future<void> appendFromSource() => runProjectAppendImport(
          context: context,
          workspace: workspace,
          workspaceNotifier: workspaceNotifier,
        );

    Future<void> addGalleryPages() => runGalleryAddPageImages(
          context: context,
          workspaceNotifier: workspaceNotifier,
        );

    Future<void> replacePage(PageSummary page) async {
      final kind = workspace.settings?.inferredImportKind;
      if (kind == null) return;

      final allowedExtensions = allowedExtensionsFor(
        kind,
        ImportKindPickerIntent.replacePage,
      )!;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result == null || result.files.isEmpty) return;
      final sourcePath = result.files.single.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        workspaceNotifier.reportError('无法读取所选文件路径');
        return;
      }

      try {
        await workspaceNotifier.replacePage(page.id, sourcePath);
      } catch (_) {}
    }

    Future<void> deletePageItem(PageSummary page) async {
      final confirmed = await showAppConfirmDialog(
        context: context,
        title: '删除页面',
        description: Text('确定删除第 ${page.sortIndex + 1} 页？'),
        confirmLabel: '删除',
        destructive: true,
      );
      if (confirmed != true) return;

      try {
        await workspaceNotifier.deletePage(page.id);
      } catch (_) {}
    }

    Future<void> setCoverPage(PageSummary page) async {
      try {
        await workspaceNotifier.setCoverPage(page.sortIndex);
        if (context.mounted) {
          showAppOperationSuccessSnackBar(
            context,
            '已设为封面（第 ${page.sortIndex + 1} 页）',
          );
        }
      } catch (_) {}
    }

    Future<void> viewPageOriginal(PageSummary page) async {
      await showPageImageViewer(context, page);
    }

    Future<void> movePageEarlier(PageSummary page) async {
      try {
        await workspaceNotifier.movePageEarlier(page);
      } catch (_) {}
    }

    Future<void> movePageLater(PageSummary page) async {
      try {
        await workspaceNotifier.movePageLater(page);
      } catch (_) {}
    }

    Widget imagesTabContent() {
      return PageThumbnailGrid(
        pages: workspace.pages,
        coverPageIndex: workspace.coverPageIndex,
        onAdd: addGalleryPages,
        onReplace: replacePage,
        onDelete: deletePageItem,
        onSetCover: setCoverPage,
        onViewOriginal: viewPageOriginal,
        onMoveEarlier: movePageEarlier,
        onMoveLater: movePageLater,
      );
    }

    Widget metadataTabContent() {
      final exportFormat =
          workspace.settings?.exportFormat ?? ExportFormatFrb.comicArchive;
      return MetadataPanel(
        key: ValueKey(
          '$exportFormat-${workspace.pages.length}-${metadataDiscardGeneration.value}',
        ),
        projectId: workspace.projectId,
        pageCount: workspace.pages.length,
        exportFormat: exportFormat,
        discardGeneration: metadataDiscardGeneration.value,
        onDirtyChanged: (dirty) => metadataDirty.value = dirty,
        onSaved: workspaceNotifier.applyMetadataSaved,
      );
    }

    Future<void> selectTab(ProjectEditorTab tab) async {
      if (tab == selectedTab.value) return;
      if (metadataDirty.value &&
          selectedTab.value == ProjectEditorTab.metadata) {
        final discard = await confirmDiscardMetadataEdits(context);
        if (!context.mounted) return;
        if (!discard) return;
        metadataDirty.value = false;
        metadataDiscardGeneration.value++;
      }
      selectedTab.value = tab;
    }

    Future<void> onBackPressed() async {
      if (!metadataDirty.value) {
        if (context.mounted) context.pop();
        return;
      }
      final discard = await confirmDiscardMetadataEdits(context);
      if (!context.mounted) return;
      if (discard) {
        metadataDirty.value = false;
        metadataDiscardGeneration.value++;
        context.pop();
      }
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
      canPop: !metadataDirty.value,
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
                      metadataDirty: metadataDirty.value,
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

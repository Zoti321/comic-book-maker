import 'package:comic_book_maker/ui/core/shell/side_tab_feature_host.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_states.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_body.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 项目属性（对话框 / 全页统一入口）。
class ProjectPropertiesFeature extends HookConsumerWidget {
  const ProjectPropertiesFeature({
    super.key,
    required this.projectId,
    this.coordinator,
    this.closeContext,
    this.form = SideTabMorphForm.page,
  });

  final String projectId;
  final SideTabFeatureCoordinator<void>? coordinator;
  final BuildContext? closeContext;
  final SideTabMorphForm form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCoordinator =
        coordinator ?? SideTabFeatureCoordinator.of<void>(context);
    final tab = useProjectPropertiesTabState(ref);
    final workspace = ref.watch(projectWorkspaceProvider(projectId));
    final settings = workspace.settings;
    final closeCtx = closeContext ?? context;

    void close() {
      if (form == SideTabMorphForm.dialog) {
        Navigator.pop(closeCtx);
      } else {
        context.pop();
      }
    }

    void onTabSelected(int index) {
      tab.setTabIndex(index);
      activeCoordinator?.tabIndex = index;
    }

    final loading = settings == null
        ? _ProjectPropertiesLoading(form: form, onClose: close)
        : null;

    final host = SideTabFeatureHost(
      spec: SideTabFeatureSpec(
        title: '项目属性',
        tabs: projectPropertiesTabs,
        tabBodyBuilder: (_, index) => ProjectPropertiesTabPanel(
          projectId: projectId,
          tabIndex: index,
        ),
        loading: loading,
      ),
      form: form,
      tabIndex: tab.tabIndex,
      onTabSelected: onTabSelected,
      dialogActions: [
        TextButton(
          onPressed: close,
          child: const Text('关闭'),
        ),
      ],
    );

    if (activeCoordinator == null) {
      return host;
    }

    return SideTabMorphPresentation(
      coordinator: activeCoordinator,
      form: form,
      child: host,
    );
  }
}

class _ProjectPropertiesLoading extends StatelessWidget {
  const _ProjectPropertiesLoading({
    required this.form,
    required this.onClose,
  });

  final SideTabMorphForm form;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return switch (form) {
      SideTabMorphForm.dialog => AlertDialog(
          title: const Text('项目属性'),
          content: const SizedBox(
            height: 200,
            child: ProjectEditorPageLoading(
              message: '正在加载项目设置…',
              compact: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: onClose,
              child: const Text('关闭'),
            ),
          ],
        ),
      SideTabMorphForm.page => Scaffold(
          appBar: AppBar(title: const Text('项目属性')),
          body: const ProjectEditorPageLoading(message: '正在加载项目设置…'),
        ),
    };
  }
}

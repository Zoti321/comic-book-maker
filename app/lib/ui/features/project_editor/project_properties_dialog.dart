import 'package:comic_book_maker/ui/core/shell/side_tab_feature_dialog.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_states.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_body.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 宽屏项目属性对话框。
class ProjectPropertiesDialog extends HookConsumerWidget {
  const ProjectPropertiesDialog({
    super.key,
    required this.projectId,
    required this.dialogContext,
    required this.coordinator,
  });

  final String projectId;
  final BuildContext dialogContext;
  final SideTabFeatureCoordinator<void> coordinator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState(coordinator.tabIndex);
    final workspace = ref.watch(projectWorkspaceProvider(projectId));
    final settings = workspace.settings;

    if (settings == null) {
      return AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    return SideTabFeatureDialog(
      title: '项目属性',
      tabs: projectPropertiesTabs,
      selectedIndex: tabIndex.value,
      onTabSelected: (index) {
        tabIndex.value = index;
        coordinator.tabIndex = index;
      },
      body: ProjectPropertiesTabPanel(
        projectId: projectId,
        tabIndex: tabIndex.value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

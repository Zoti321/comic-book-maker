import 'package:comic_book_maker/ui/core/shell/side_tab_feature_page.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_states.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_body.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 窄屏项目属性全页。
class ProjectPropertiesPage extends ConsumerWidget {
  const ProjectPropertiesPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(projectWorkspaceProvider(projectId));
    final settings = workspace.settings;

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('项目属性')),
        body: const ProjectEditorPageLoading(message: '正在加载项目设置…'),
      );
    }

    return SideTabFeaturePage(
      title: '项目属性',
      tabs: projectPropertiesTabs,
      tabBodies: [
        for (var i = 0; i < projectPropertiesTabs.length; i++)
          sideTabFeaturePageTabBody(
            ProjectPropertiesTabPanel(projectId: projectId, tabIndex: i),
          ),
      ],
    );
  }
}

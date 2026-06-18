import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_dialog.dart';
import 'package:flutter/material.dart';

/// 打开项目属性：窄屏全页，宽屏对话框；打开后随窗口双向变形。
Future<void> openProjectProperties({
  required BuildContext context,
  required String projectId,
}) {
  return openSideTabFeature<void>(
    context: context,
    compactPageLocation: AppRoutes.projectPropertiesPath(projectId),
    dialogBuilder: (dialogContext, coordinator) => ProjectPropertiesDialog(
      projectId: projectId,
      dialogContext: dialogContext,
      coordinator: coordinator,
    ),
  );
}

import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_dialogs.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 打开项目属性：窄屏全页，宽屏对话框。
Future<void> openProjectProperties({
  required BuildContext context,
  required String projectId,
}) {
  if (isCompact(context)) {
    return GoRouter.of(context).push<void>(AppRoutes.projectPropertiesPath(projectId));
  }
  return showProjectPropertiesDialog(context: context, projectId: projectId);
}

Future<void> showProjectPropertiesDialog({
  required BuildContext context,
  required String projectId,
}) {
  return showProjectEditorFeatureDialog<void>(
    context: context,
    builder: (dialogContext) => ProjectPropertiesDialog(
      projectId: projectId,
      dialogContext: dialogContext,
    ),
  );
}

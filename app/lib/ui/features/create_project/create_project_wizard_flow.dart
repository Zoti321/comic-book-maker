import 'dart:async';

import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:comic_book_maker/ui/core/design_system/app_toast_controller.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_feature.dart';
import 'package:comic_book_maker/ui/features/create_project/providers/create_project_wizard_session_provider.dart';
import 'package:flutter/material.dart';

/// 打开新建项目向导；确认后在后台创建，通过右下角 Toast 反馈进度。
Future<void> runCreateProjectWizard({
  required BuildContext context,
  required LibraryOperations library,
}) async {
  if (!context.mounted) return;

  final draft = await _openCreateProjectWizard(context);
  if (draft == null || !draft.canCreate) {
    return;
  }

  final displayTitle = _createProjectDisplayTitle(draft);
  final toast = AppToastController.instance.showLoading(
    message: '正在创建「$displayTitle」…',
  );

  unawaited(
    _createProjectInBackground(
      draft: draft,
      library: library,
      toast: toast,
    ),
  );
}

Future<CreateProjectDraft?> _openCreateProjectWizard(BuildContext context) {
  return openSideTabFeature<CreateProjectDraft>(
    context: context,
    compactPageLocation: AppRoutes.projectCreate,
    session: createProjectWizardSideTabSession,
    dialogBuilder: (dialogContext, coordinator) => CreateProjectWizardFeature(
      coordinator: coordinator,
      closeContext: dialogContext,
      form: SideTabMorphForm.dialog,
    ),
  );
}

Future<void> _createProjectInBackground({
  required CreateProjectDraft draft,
  required LibraryOperations library,
  required AppToastHandle toast,
}) async {
  try {
    final created = await library.createFromDraft(draft);
    toast.success(
      '「${created.title}」已创建',
      action: AppToastAction(
        label: '打开项目',
        onPressed: () {
          library.recordProjectOpened(projectId: created.id);
          openProjectEditor(created);
        },
      ),
    );
  } catch (error) {
    final summary = _createProjectFailureSummary(error);
    toast.error(
      '创建失败：$summary',
      action: AppToastAction(
        label: '查看详情',
        onPressed: () {
          final navContext = rootNavigatorKey.currentContext;
          if (navContext == null || !navContext.mounted) return;
          final message = error.toString();

          showAppOverlayDialog<void>(
            context: navContext,
            builder: (dialogContext) {
              final scheme = Theme.of(dialogContext).colorScheme;
              return AlertDialog(
                title: const Text('创建失败'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    Text(
                      '请确认文件未损坏且格式受支持，然后重试。',
                      style: Theme.of(dialogContext)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('知道了'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

String _createProjectDisplayTitle(CreateProjectDraft draft) {
  final trimmed = draft.projectTitle.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  final source = draft.importSource;
  return switch (source) {
    CreateProjectArchiveImport(:final sourcePath) =>
      _titleFromArchivePath(sourcePath),
    CreateProjectImageImport() => '新项目',
    null => '新项目',
  };
}

String _titleFromArchivePath(String sourcePath) {
  final normalized = sourcePath.replaceAll(r'\', '/');
  final name = normalized.split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) {
    return name;
  }
  return name.substring(0, dot);
}

String _createProjectFailureSummary(Object error, {int maxLength = 80}) {
  final text = switch (error) {
    CreateProjectValidationException(:final message) => message,
    _ => error.toString(),
  };
  final trimmed = text.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength)}…';
}

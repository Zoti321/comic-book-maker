import 'dart:async';

import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_dialog.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 打开新建项目向导；确认后在后台创建，通过 [AppToast] 反馈进度。
Future<void> runCreateProjectWizard({
  required BuildContext context,
  required LibraryOperations library,
}) async {
  final draft = await showAppFeatureDialog<CreateProjectDraft>(
    context: context,
    builder: (dialogContext) => const CreateProjectWizardDialog(),
  );
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
          toast.dismiss();
        },
      ),
    );
  } catch (error) {
    toast.error(
      '创建失败：${_createProjectFailureSummary(error)}',
      action: AppToastAction(
        label: '查看详情',
        onPressed: () {
          final navContext = rootNavigatorKey.currentContext;
          if (navContext == null || !navContext.mounted) return;
          unawaited(
            showAppOperationFailure(
              navContext,
              title: '创建失败',
              message: error.toString(),
              nextStepHint: '请确认文件未损坏且格式受支持，然后重试。',
            ),
          );
          toast.dismiss();
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

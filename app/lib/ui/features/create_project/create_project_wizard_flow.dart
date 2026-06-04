import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_draft.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_dialog.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 打开新建项目向导；成功返回新 [ProjectSummary]，取消返回 `null`。
Future<ProjectSummary?> runCreateProjectWizard({
  required BuildContext context,
  required LibraryOperations library,
}) async {
  final draft = await showAppFeatureDialog<CreateProjectDraft>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const CreateProjectWizardDialog(),
  );
  if (draft == null || !context.mounted || !draft.canCreate) {
    return null;
  }

  ProjectSummary? created;
  try {
    created = await runAppBlockingOperation(
      context: context,
      message: '正在创建项目…',
      operation: () => library.createFromDraft(draft),
    );
  } catch (e) {
    if (!context.mounted) return null;
    await showAppOperationFailure(
      context,
      title: '创建失败',
      message: e.toString(),
      nextStepHint: '请确认文件未损坏且格式受支持，然后重试。',
    );
    return null;
  }

  return created;
}

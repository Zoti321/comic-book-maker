import 'dart:async';

import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_dialog.dart';
import 'package:flutter/material.dart';

/// 打开新建项目向导；确认后在后台创建，通过 Material SnackBar 反馈进度。
Future<void> runCreateProjectWizard({
  required BuildContext context,
  required LibraryOperations library,
}) async {
  final draft = await showDialog<CreateProjectDraft>(
    context: context,
    builder: (dialogContext) => const CreateProjectWizardDialog(),
  );
  if (draft == null || !draft.canCreate) {
    return;
  }

  final displayTitle = _createProjectDisplayTitle(draft);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final loadingController = messenger.showSnackBar(
    SnackBar(
      content: Text('正在创建「$displayTitle」…'),
      duration: const Duration(days: 1),
    ),
  );

  unawaited(
    _createProjectInBackground(
      draft: draft,
      library: library,
      context: context,
      loadingController: loadingController,
    ),
  );
}

Future<void> _createProjectInBackground({
  required CreateProjectDraft draft,
  required LibraryOperations library,
  required BuildContext context,
  required ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      loadingController,
}) async {
  try {
    final created = await library.createFromDraft(draft);
    if (!context.mounted) return;
    loadingController.close();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${created.title}」已创建'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: '打开项目',
          onPressed: () {
            library.recordProjectOpened(projectId: created.id);
            openProjectEditor(created);
          },
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    loadingController.close();

    final summary = _createProjectFailureSummary(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('创建失败：$summary'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '查看详情',
          onPressed: () {
            final navContext = rootNavigatorKey.currentContext;
            if (navContext == null || !navContext.mounted) return;
            final message = error.toString();

            showDialog<void>(
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

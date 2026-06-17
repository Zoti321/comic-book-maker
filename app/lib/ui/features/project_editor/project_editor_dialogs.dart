import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 项目编辑相关功能对话框（限宽壳层）。
Future<T?> showProjectEditorFeatureDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => _ProjectEditorFeatureDialogFrame(
      child: builder(dialogContext),
    ),
  );
}

class _ProjectEditorFeatureDialogFrame extends StatelessWidget {
  const _ProjectEditorFeatureDialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 600) return child;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: sideTabFeatureDialogMaxWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }
}

Future<bool?> showProjectEditorConfirmDialog({
  required BuildContext context,
  required String title,
  required Widget description,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: description,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

Future<void> showProjectEditorAlertDialog({
  required BuildContext context,
  required String title,
  required Widget description,
  String actionLabel = '知道了',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: description,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

Future<void> showProjectEditorOperationFailure(
  BuildContext context, {
  required String title,
  required String message,
  String? nextStepHint,
}) {
  final description = nextStepHint == null
      ? Text(message)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Text(
              nextStepHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        );

  return showProjectEditorAlertDialog(
    context: context,
    title: title,
    description: description,
  );
}

Future<T> runProjectEditorBlockingOperation<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() operation,
}) async {
  if (!context.mounted) {
    throw StateError('Context is not mounted');
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;

  try {
    return await operation();
  } finally {
    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

Future<T> runProjectEditorDismissibleBackgroundOperation<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() operation,
  String? dismissHint,
}) async {
  if (!context.mounted) {
    throw StateError('Context is not mounted');
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  var loadingOpen = true;
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
            if (dismissHint != null) ...[
              const SizedBox(height: 12),
              Text(
                dismissHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  navigator.push(route).whenComplete(() => loadingOpen = false);
  await WidgetsBinding.instance.endOfFrame;

  try {
    return await operation();
  } finally {
    if (loadingOpen && route.isActive) {
      navigator.removeRoute(route);
    }
  }
}

void showProjectEditorExportSuccessSnackBar(
  BuildContext context, {
  required bool deletedProject,
}) {
  final message = deletedProject ? '项目已导出并已删除' : '导出完成';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showProjectEditorAppendImportOutcome(
  BuildContext context, {
  required int addedPageCount,
  required List<String> warnings,
}) async {
  if (warnings.isEmpty) return;

  await showProjectEditorAlertDialog(
    context: context,
    title: '追加完成（有警告）',
    description: Text(
      '已追加 $addedPageCount 页。\n\n${warnings.join('\n')}',
    ),
  );
}

/// 编辑页追加导入：选择 CBZ、CBR 或 CB7。
Future<ArchiveFormatFrb?> showProjectEditorAppendArchiveSheet(
  BuildContext context,
) {
  return showModalBottomSheet<ArchiveFormatFrb>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '从漫画压缩包导入',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '追加页面到当前项目',
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(sheetContext, ArchiveFormatFrb.cbz),
              icon: const Icon(LucideIcons.folderArchive),
              label: const Text('选择 CBZ'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(sheetContext, ArchiveFormatFrb.cbr),
              icon: const Icon(LucideIcons.archive),
              label: const Text('选择 CBR'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(sheetContext, ArchiveFormatFrb.cb7),
              icon: const Icon(LucideIcons.archive),
              label: const Text('选择 CB7'),
            ),
          ],
        ),
      );
    },
  );
}

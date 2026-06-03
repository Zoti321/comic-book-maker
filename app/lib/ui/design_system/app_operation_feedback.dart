import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/app_dialog.dart';
import 'package:comic_book_maker/ui/design_system/app_snack_bar.dart';
import 'package:flutter/material.dart';

export 'app_blocking_loading.dart';

/// 操作失败：Dialog 说明原因与建议下一步（不用 SnackBar）。
Future<void> showAppOperationFailure(
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

  return showAppAlertDialog(
    context: context,
    title: title,
    description: description,
  );
}

/// 轻量成功反馈（追加页数等）。
void showAppOperationSuccessSnackBar(BuildContext context, String message) {
  showAppToast(context, message);
}

/// 导出成功：Dialog 展示完整路径（避免 SnackBar + Dialog 混用）。
Future<void> showAppExportSuccessDialog(
  BuildContext context, {
  required String destinationPath,
  required bool deletedProject,
}) {
  final body = deletedProject
      ? '项目已导出并从库中删除。\n\n保存位置：\n$destinationPath'
      : '文件已保存至：\n$destinationPath';

  return showAppAlertDialog(
    context: context,
    title: '导出完成',
    description: Text(body),
    actionLabel: deletedProject ? '返回漫画库' : '知道了',
  );
}

/// 追加/导入完成：有警告用 Dialog，否则 SnackBar。
Future<void> showAppAppendImportOutcome(
  BuildContext context, {
  required int addedPageCount,
  required List<String> warnings,
}) async {
  if (warnings.isNotEmpty) {
    await showAppAlertDialog(
      context: context,
      title: '追加完成（有警告）',
      description: Text(
        '已追加 $addedPageCount 页。\n\n${warnings.join('\n')}',
      ),
    );
    return;
  }
  showAppOperationSuccessSnackBar(context, '已追加 $addedPageCount 页');
}

/// 漫画库导入 / 新建成功：有警告先 Dialog；SnackBar 可自动消失，并提供「打开项目」。
Future<void> showAppLibraryImportOutcome(
  BuildContext context, {
  required ProjectSummary project,
  required List<String> warnings,
  required VoidCallback onOpenProject,
  String? successMessage,
}) async {
  if (warnings.isNotEmpty) {
    await showAppAlertDialog(
      context: context,
      title: '导入完成（有警告）',
      description: Text(warnings.join('\n')),
    );
    if (!context.mounted) return;
  }

  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final message = successMessage ?? '已导入「${project.title}」';

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      closeIconColor: Theme.of(context).colorScheme.onInverseSurface,
      action: SnackBarAction(
        label: '打开项目',
        onPressed: () {
          messenger.hideCurrentSnackBar();
          onOpenProject();
        },
      ),
    ),
  );
}

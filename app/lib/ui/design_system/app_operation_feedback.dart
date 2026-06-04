import 'package:comic_book_maker/ui/design_system/app_dialog.dart';
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

/// 追加/导入完成：仅在有警告时用 Dialog；成功时 UI 已反映页数变化。
Future<void> showAppAppendImportOutcome(
  BuildContext context, {
  required int addedPageCount,
  required List<String> warnings,
}) async {
  if (warnings.isEmpty) return;

  await showAppAlertDialog(
    context: context,
    title: '追加完成（有警告）',
    description: Text(
      '已追加 $addedPageCount 页。\n\n${warnings.join('\n')}',
    ),
  );
}

/// 漫画库导入完成：仅在有警告时用 Dialog；成功时项目已出现在列表中。
Future<void> showAppLibraryImportOutcome(
  BuildContext context, {
  required List<String> warnings,
}) async {
  if (warnings.isEmpty) return;

  await showAppAlertDialog(
    context: context,
    title: '导入完成（有警告）',
    description: Text(warnings.join('\n')),
  );
}

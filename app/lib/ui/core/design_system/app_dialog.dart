import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:flutter/material.dart';

/// 功能对话框（Export 等）；宽屏限制最大宽度。
Future<T?> showAppFeatureDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      final dialog = builder(context);
      final width = MediaQuery.sizeOf(context).width;
      if (width <= 600) return dialog;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: appSheetMaxWidth + 40),
            child: dialog,
          ),
        ),
      );
    },
  );
}

/// 显示 M3 风格对话框。
///
/// [actionsBuilder] 接收对话框内的 [BuildContext]，用于 `Navigator.pop` 关闭弹层，
/// 勿使用调用方页面的 context（否则会误 pop 路由栈）。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppDialog(
      title: title,
      content: content,
      actions: actionsBuilder?.call(dialogContext),
    ),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    );
  }
}

/// 确认对话框；返回 `true` / `false`，取消为 `null` 或 `false`。
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required Widget description,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool destructive = false,
}) {
  return showAppDialog<bool>(
    context: context,
    title: title,
    content: description,
    actionsBuilder: (dialogContext) => [
      AppButton(
        variant: AppButtonVariant.outline,
        onPressed: () => Navigator.pop(dialogContext, false),
        child: Text(cancelLabel),
      ),
      AppButton(
        variant: destructive
            ? AppButtonVariant.destructive
            : AppButtonVariant.primary,
        onPressed: () => Navigator.pop(dialogContext, true),
        child: Text(confirmLabel),
      ),
    ],
  );
}

/// 单按钮提示对话框。
Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  required Widget description,
  String actionLabel = '知道了',
}) {
  return showAppDialog<void>(
    context: context,
    title: title,
    content: description,
    actionsBuilder: (dialogContext) => [
      AppButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: Text(actionLabel),
      ),
    ],
  );
}

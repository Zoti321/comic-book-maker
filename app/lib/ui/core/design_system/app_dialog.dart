import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 功能对话框（Export 等）；宽屏限制最大宽度。
Future<T?> showAppFeatureDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double? maxWidth,
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? sideTabFeatureDialogMaxWidth(context),
            ),
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
    this.titleTrailing,
    this.actions,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });

  final String title;
  final Widget? titleTrailing;
  final Widget content;
  final List<Widget>? actions;

  /// body 内边距；侧栏 Tab 功能对话框传 [EdgeInsets.zero] 以使 shell 贴边。
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final actionWidgets = actions;
    final hasActions = actionWidgets != null && actionWidgets.isNotEmpty;
    final maxHeight = MediaQuery.sizeOf(context).height - 48;

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorder,
        side: BorderSide(color: scheme.outline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 280, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (titleTrailing != null) ...[
                    const Spacer(),
                    Flexible(child: titleTrailing!),
                  ],
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: scheme.outline),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: hasActions
                    ? contentPadding
                    : contentPadding.add(const EdgeInsets.only(bottom: 8)),
                child: SizedBox(width: double.maxFinite, child: content),
              ),
            ),
            if (hasActions) ...[
              Divider(height: 1, thickness: 1, color: scheme.outline),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actionWidgets.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      actionWidgets[i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
        variant: AppButtonVariant.secondary,
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

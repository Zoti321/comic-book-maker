import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 功能对话框（Export 等）；宽屏限制最大宽度。
///
/// 最大宽度在 [AppFeatureDialogFrame] 的每次 build 时按当前 [MediaQuery] 断点计算
///（[sideTabFeatureDialogMaxWidth]），窗口缩放后即时生效，无需关闭重开。
Future<T?> showAppFeatureDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppFeatureDialogFrame(
      child: builder(dialogContext),
    ),
  );
}

/// 侧栏 Tab 功能对话框（新建项目、项目属性等）；宽屏居中限宽。
Future<T?> showSideTabFeatureDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppFeatureDialogFrame(
      child: builder(dialogContext),
    ),
  );
}

/// 功能 / 侧栏 Tab 对话框外层限宽壳；独立 widget 以便 [MediaQuery] 变化时重建。
class AppFeatureDialogFrame extends StatelessWidget {
  const AppFeatureDialogFrame({super.key, required this.child});

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
    this.contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    this.showDividers = true,
    this.scrollable = true,
  });

  final String title;
  final Widget? titleTrailing;
  final Widget content;
  final List<Widget>? actions;

  /// body 内边距；侧栏 Tab 功能对话框传 [EdgeInsets.zero] 以使 shell 贴边。
  final EdgeInsetsGeometry contentPadding;

  /// 是否在标题 / 内容 / 操作区之间显示分割线。
  final bool showDividers;

  /// `false` 时内容区不外包 [SingleChildScrollView]，由子组件自行滚动（侧栏 Tab）。
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final actionWidgets = actions;
    final hasActions = actionWidgets != null && actionWidgets.isNotEmpty;
    final maxHeight =
        MediaQuery.sizeOf(context).height - AppLayout.dialogViewportMargin;
    final expandContent = !scrollable;

    final titlePadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      showDividers ? AppSpacing.md : AppSpacing.lg,
    );
    final actionsPadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      showDividers ? AppSpacing.sm + AppSpacing.xs : AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.lg,
    );

    Widget contentChild;
    if (scrollable) {
      contentChild = Flexible(
        fit: FlexFit.loose,
        child: SingleChildScrollView(
          padding: hasActions
              ? contentPadding
              : contentPadding.add(const EdgeInsets.only(bottom: AppSpacing.sm)),
          child: SizedBox(width: double.maxFinite, child: content),
        ),
      );
    } else {
      contentChild = Expanded(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.sideTabDialogMinHeight,
          ),
          child: content,
        ),
      );
    }

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
          mainAxisSize:
              expandContent ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: titlePadding,
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
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
            if (showDividers)
              Divider(height: 1, thickness: 1, color: scheme.outline),
            contentChild,
            if (hasActions) ...[
              if (showDividers)
                Divider(height: 1, thickness: 1, color: scheme.outline),
              Padding(
                padding: actionsPadding,
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

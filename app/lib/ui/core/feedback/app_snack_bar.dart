import 'dart:math' as math;

import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// M3 floating SnackBar 最大宽度（与 [m3.material.io/components/snackbar/specs] 一致）。
const kAppSnackBarMaxWidth = 568.0;

/// 按断点计算 SnackBar 边距：`compact` 底部居中；`medium+` 窗口右下角。
EdgeInsets appSnackBarMarginFor(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (isCompact(context)) {
    return EdgeInsets.only(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.md,
    );
  }

  const right = AppSpacing.lg;
  const bottom = AppSpacing.lg;
  final left = math.max(AppSpacing.md, width - kAppSnackBarMaxWidth - right);
  return EdgeInsets.only(left: left, right: right, bottom: bottom);
}

/// 轻量操作反馈。壳层 [AppShell] 与编辑页 [Scaffold] 提供挂载点。
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      margin: appSnackBarMarginFor(context),
      showCloseIcon: action != null,
      closeIconColor: Theme.of(context).colorScheme.onInverseSurface,
    ),
  );
}

/// 与迁移前 [showAppToast] 等价的便捷 API。
void showAppToast(BuildContext context, String message) {
  showAppSnackBar(context, message);
}

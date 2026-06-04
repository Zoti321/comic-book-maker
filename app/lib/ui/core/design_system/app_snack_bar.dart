import 'package:flutter/material.dart';

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
      showCloseIcon: action != null,
      closeIconColor: Theme.of(context).colorScheme.onInverseSurface,
    ),
  );
}

/// 与迁移前 [showAppToast] 等价的便捷 API。
void showAppToast(BuildContext context, String message) {
  showAppSnackBar(context, message);
}

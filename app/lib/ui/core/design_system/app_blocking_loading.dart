import 'package:flutter/material.dart';

/// 全站唯一的阻塞式 loading 弹层（不可取消）。
Future<void> showAppBlockingLoading(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => AppBlockingLoadingDialog(message: message),
  );
}

void hideAppBlockingLoading(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

class AppBlockingLoadingDialog extends StatelessWidget {
  const AppBlockingLoadingDialog({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }
}

/// 在阻塞 loading 下执行异步操作；保证全程只出现一种 loading 弹层。
Future<T> runAppBlockingOperation<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() operation,
}) async {
  if (!context.mounted) {
    throw StateError('Context is not mounted');
  }

  // 勿 await showDialog：其 Future 在弹层 pop 后才完成，会导致永远等不到 operation。
  showAppBlockingLoading(context, message: message);
  await WidgetsBinding.instance.endOfFrame;

  try {
    return await operation();
  } finally {
    if (context.mounted) {
      hideAppBlockingLoading(context);
    }
  }
}

/// 可关闭的 loading 弹层（点击遮罩或返回键关闭；任务仍在后台继续）。
Future<void> showAppDismissibleLoading(
  BuildContext context, {
  required String message,
  String? hint,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (dialogContext) => AppDismissibleLoadingDialog(
      message: message,
      hint: hint,
    ),
  );
}

class AppDismissibleLoadingDialog extends StatelessWidget {
  const AppDismissibleLoadingDialog({
    super.key,
    required this.message,
    this.hint,
  });

  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 展示可关闭 loading 并在后台执行操作；用户提前关闭弹层不会取消任务。
Future<T> runAppDismissibleBackgroundOperation<T>({
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
    builder: (dialogContext) => AppDismissibleLoadingDialog(
      message: message,
      hint: dismissHint,
    ),
  );

  // 勿 await push：其 Future 在弹层 pop 后才完成，会导致永远等不到 operation。
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

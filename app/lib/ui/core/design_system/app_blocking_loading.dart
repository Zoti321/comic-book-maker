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

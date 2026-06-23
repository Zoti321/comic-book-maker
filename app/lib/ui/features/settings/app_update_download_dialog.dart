import 'package:comic_book_maker/domain/models/app_update_download_progress.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:flutter/material.dart';

Future<void> showAppUpdateDownloadDialog({
  required BuildContext context,
  required ValueNotifier<AppUpdateDownloadProgress> progress,
}) {
  return showAppOverlayDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('正在下载更新'),
          content: ValueListenableBuilder<AppUpdateDownloadProgress>(
            valueListenable: progress,
            builder: (context, value, _) {
              return SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: value.fraction),
                    if (value.label != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        value.label!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

void hideAppUpdateDownloadDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

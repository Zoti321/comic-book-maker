import 'package:comic_book_maker/domain/use_cases/check_app_update.dart';
import 'package:comic_book_maker/providers/app_update_providers.dart';
import 'package:comic_book_maker/providers/app_version_provider.dart';
import 'package:comic_book_maker/providers/auto_update_provider.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_dialog.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
Future<void> runStartupAppUpdateCheck({
  required WidgetRef ref,
}) async {
  if (!isAppUpdateSupportedPlatform()) {
    return;
  }

  final autoUpdateEnabled = await ref.read(autoUpdateProvider.future);
  if (!autoUpdateEnabled) {
    return;
  }

  if (ref.read(appUpdateSessionProvider)) {
    return;
  }

  try {
    final currentVersion = await ref.read(appVersionProvider.future);
    final result = await ref
        .read(checkAppUpdateProvider)
        .call(currentVersion: currentVersion);

    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      return;
    }

    if (result case AppUpdateAvailable(:final release)) {
      await showAppUpdateAvailableDialog(
        context: dialogContext,
        ref: ref,
        release: release,
      );
    }
  } on Object {
    // 启动时自动检查失败静默忽略。
  }
}

import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/providers/app_update_providers.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_download_flow.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_release_notes_content.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAppUpdateAvailableDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AppUpdateRelease release,
}) {
  return showAppOverlayDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('发现新版本 ${release.version}'),
        content: SizedBox(
          width: 480,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: AppUpdateReleaseNotesContent(release: release),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(appUpdateSessionProvider.notifier).dismissForSession();
              Navigator.pop(dialogContext);
            },
            child: const Text('稍后提醒'),
          ),
          OutlinedButton(
            onPressed: () => _openReleasePage(release.releasePageUrl),
            child: const Text('查看更新'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              runAppUpdateDownloadAndInstall(
                context: context,
                ref: ref,
                release: release,
              );
            },
            child: const Text('立即更新'),
          ),
        ],
      );
    },
  );
}

Future<void> _openReleasePage(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('无法打开链接：$url');
  }
}

import 'package:comic_book_maker/data/platform/android_apk_installer.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:flutter/material.dart';

Future<void> showAppUpdateInstallPermissionDialog({
  required BuildContext context,
}) {
  const installer = AndroidApkInstaller();

  return showAppOverlayDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('需要安装权限'),
        content: const Text(
          '安装更新需要允许本应用「安装未知应用」。请在系统设置中开启后，再次点击「立即更新」完成安装。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await installer.openInstallPermissionSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      );
    },
  );
}

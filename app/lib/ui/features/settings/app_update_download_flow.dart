import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_download_progress.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/providers/app_update_providers.dart';
import 'package:comic_book_maker/ui/core/design_system/app_snack_bar.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_download_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> runAppUpdateDownloadAndInstall({
  required BuildContext context,
  required WidgetRef ref,
  required AppUpdateRelease release,
}) async {
  final progress = ValueNotifier(
    const AppUpdateDownloadProgress(receivedBytes: 0, totalBytes: null),
  );

  if (!context.mounted) return;

  // 勿 await showDialog：其 Future 在弹层关闭后才完成。
  showAppUpdateDownloadDialog(context: context, progress: progress);
  await WidgetsBinding.instance.endOfFrame;

  try {
    final filePath = await ref.read(downloadAppUpdateProvider).call(
          release,
          onProgress: (receivedBytes, totalBytes) {
            progress.value = AppUpdateDownloadProgress(
              receivedBytes: receivedBytes,
              totalBytes: totalBytes,
            );
          },
        );
    if (!context.mounted) return;

    hideAppUpdateDownloadDialog(context);
    await WidgetsBinding.instance.endOfFrame;

    final message = await ref.read(installAppUpdateProvider).call(
          filePath: filePath,
        );
    if (!context.mounted) return;
    showAppSnackBar(context, message);
  } on DioException catch (error) {
    if (!context.mounted) return;
    hideAppUpdateDownloadDialog(context);
    showAppSnackBar(context, '下载失败：${_dioMessage(error)}');
  } on AppUpdateRepositoryException catch (error) {
    if (!context.mounted) return;
    hideAppUpdateDownloadDialog(context);
    showAppSnackBar(context, '下载失败：${error.message}');
  } on Object catch (error) {
    if (!context.mounted) return;
    hideAppUpdateDownloadDialog(context);
    showAppSnackBar(context, '下载失败：$error');
  } finally {
    progress.dispose();
  }
}

String _dioMessage(DioException error) {
  final response = error.response;
  if (response != null) {
    return 'HTTP ${response.statusCode}';
  }
  return error.message ?? error.type.name;
}

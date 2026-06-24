import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/use_cases/check_app_update.dart';
import 'package:comic_book_maker/providers/app_update_providers.dart';
import 'package:comic_book_maker/ui/core/feedback/app_snack_bar.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> runManualAppUpdateCheck({
  required BuildContext context,
  required WidgetRef ref,
  required String currentVersion,
}) async {
  try {
    final result =
        await ref.read(checkAppUpdateProvider).call(currentVersion: currentVersion);
    if (!context.mounted) return;

    switch (result) {
      case AppUpdateUpToDate():
        _showSettingsSnackBar(context, '已是最新版本');
      case AppUpdateAvailable(:final release):
        await showAppUpdateAvailableDialog(
          context: context,
          ref: ref,
          release: release,
        );
    }
  } on DioException catch (error) {
    if (!context.mounted) return;
    _showSettingsSnackBar(context, '检查更新失败：${_dioMessage(error)}');
  } on AppUpdateRepositoryException catch (error) {
    if (!context.mounted) return;
    _showSettingsSnackBar(context, '检查更新失败：${error.message}');
  } on Object catch (error) {
    if (!context.mounted) return;
    _showSettingsSnackBar(context, '检查更新失败：$error');
  }
}

String _dioMessage(DioException error) {
  final response = error.response;
  if (response != null) {
    return 'HTTP ${response.statusCode}';
  }
  return error.message ?? error.type.name;
}

void _showSettingsSnackBar(BuildContext context, String message) {
  showAppSnackBar(context, message);
}

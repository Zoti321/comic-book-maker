import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

/// Android 侧载 APK 安装：安装权限检查与调起系统安装器。
class AndroidApkInstaller {
  const AndroidApkInstaller();

  static const _channel = MethodChannel(
    'com.comicbookmaker.comic_book_maker/apk_install',
  );

  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final result = await _channel.invokeMethod<bool>(
      'canRequestPackageInstalls',
    );
    return result ?? false;
  }

  Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>('openInstallPermissionSettings');
  }

  Future<void> installApk(String filePath) async {
    if (!Platform.isAndroid) {
      throw StateError('仅 Android 支持 APK 安装');
    }

    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw AndroidApkInstallException(
        result.message.isEmpty ? '无法调起系统安装器' : result.message,
      );
    }
  }
}

class AndroidApkInstallException implements Exception {
  const AndroidApkInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:io';

import 'package:comic_book_maker/data/platform/android_apk_installer.dart';
import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';

typedef OpenDirectoryInFileManager = Future<void> Function(String directoryPath);

typedef LaunchInstallerExecutable = Future<void> Function(String filePath);

/// 应用已下载更新包，但尚未获得「安装未知应用」权限。
class AppUpdateInstallPermissionRequired implements Exception {
  const AppUpdateInstallPermissionRequired();
}

class InstallAppUpdate {
  InstallAppUpdate({
    OpenDirectoryInFileManager? openDirectory,
    LaunchInstallerExecutable? launchInstaller,
    AppUpdateTargetPlatform Function()? platform,
    AndroidApkInstaller? androidApkInstaller,
  })  : _openDirectory = openDirectory ?? _defaultOpenDirectory,
        _launchInstaller = launchInstaller ?? _defaultLaunchInstaller,
        _platform = platform ?? currentAppUpdateTargetPlatform,
        _androidApkInstaller = androidApkInstaller ?? const AndroidApkInstaller();

  final OpenDirectoryInFileManager _openDirectory;
  final LaunchInstallerExecutable _launchInstaller;
  final AppUpdateTargetPlatform Function() _platform;
  final AndroidApkInstaller _androidApkInstaller;

  Future<String> call({required String filePath}) async {
    return switch (_platform()) {
      AppUpdateTargetPlatform.windows => _installWindows(filePath),
      AppUpdateTargetPlatform.macos => _installMacOs(filePath),
      AppUpdateTargetPlatform.linux => _installLinux(filePath),
      AppUpdateTargetPlatform.android => _installAndroid(filePath),
    };
  }

  Future<String> _installWindows(String filePath) async {
    await _launchInstaller(filePath);
    return '安装程序已启动，请按向导完成更新';
  }

  Future<String> _installMacOs(String filePath) async {
    await _openDirectory(File(filePath).parent.path);
    return '请在 Finder 中将新版本拖入「应用程序」替换旧版本';
  }

  Future<String> _installLinux(String filePath) async {
    await _openDirectory(File(filePath).parent.path);
    return '请解压下载的包并替换现有安装';
  }

  Future<String> _installAndroid(String filePath) async {
    final canInstall = await _androidApkInstaller.canRequestPackageInstalls();
    if (!canInstall) {
      throw const AppUpdateInstallPermissionRequired();
    }

    try {
      await _androidApkInstaller.installApk(filePath);
    } on AndroidApkInstallException catch (error) {
      final message = error.message;
      if (message.contains('conflict') || message.contains('签名')) {
        throw AndroidApkInstallException(
          '安装失败：签名与已安装版本不一致，请先卸载旧版后重试',
        );
      }
      rethrow;
    }

    return '请在系统安装界面中确认安装';
  }
}

Future<void> _defaultLaunchInstaller(String filePath) {
  return Process.start(
    filePath,
    const [],
    mode: ProcessStartMode.detached,
  );
}

Future<void> _defaultOpenDirectory(String directoryPath) async {
  if (Platform.isWindows) {
    await Process.run('explorer', [directoryPath]);
    return;
  }
  if (Platform.isMacOS) {
    await Process.run('open', [directoryPath]);
    return;
  }
  if (Platform.isLinux) {
    await Process.run('xdg-open', [directoryPath]);
    return;
  }
  throw StateError('当前平台不支持打开目录：${Platform.operatingSystem}');
}

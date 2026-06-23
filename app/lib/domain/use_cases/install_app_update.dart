import 'dart:io';

import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';

typedef OpenDirectoryInFileManager = Future<void> Function(String directoryPath);

typedef LaunchInstallerExecutable = Future<void> Function(String filePath);

class InstallAppUpdate {
  InstallAppUpdate({
    OpenDirectoryInFileManager? openDirectory,
    LaunchInstallerExecutable? launchInstaller,
    AppUpdateTargetPlatform Function()? platform,
  })  : _openDirectory = openDirectory ?? _defaultOpenDirectory,
        _launchInstaller = launchInstaller ?? _defaultLaunchInstaller,
        _platform = platform ?? currentAppUpdateTargetPlatform;

  final OpenDirectoryInFileManager _openDirectory;
  final LaunchInstallerExecutable _launchInstaller;
  final AppUpdateTargetPlatform Function() _platform;

  Future<String> call({required String filePath}) async {
    return switch (_platform()) {
      AppUpdateTargetPlatform.windows => _installWindows(filePath),
      AppUpdateTargetPlatform.macos => _installMacOs(filePath),
      AppUpdateTargetPlatform.linux => _installLinux(filePath),
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

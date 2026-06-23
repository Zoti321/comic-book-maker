import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';
import 'package:comic_book_maker/domain/use_cases/install_app_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('windows install launches installer and returns guidance', () async {
    String? launchedPath;

    final installer = InstallAppUpdate(
      platform: () => AppUpdateTargetPlatform.windows,
      launchInstaller: (path) async {
        launchedPath = path;
      },
      openDirectory: (_) async {},
    );

    final message = await installer.call(filePath: r'C:\temp\setup.exe');

    expect(launchedPath, r'C:\temp\setup.exe');
    expect(message, '安装程序已启动，请按向导完成更新');
  });

  test('macos install opens directory and returns guidance', () async {
    String? openedDirectory;

    final installer = InstallAppUpdate(
      platform: () => AppUpdateTargetPlatform.macos,
      launchInstaller: (_) async {},
      openDirectory: (directory) async {
        openedDirectory = directory;
      },
    );

    final message = await installer.call(filePath: '/tmp/update.zip');

    expect(openedDirectory, '/tmp');
    expect(message, '请在 Finder 中将新版本拖入「应用程序」替换旧版本');
  });

  test('linux install opens directory and returns guidance', () async {
    String? openedDirectory;

    final installer = InstallAppUpdate(
      platform: () => AppUpdateTargetPlatform.linux,
      launchInstaller: (_) async {},
      openDirectory: (directory) async {
        openedDirectory = directory;
      },
    );

    final message = await installer.call(filePath: '/tmp/update.tar.gz');

    expect(openedDirectory, '/tmp');
    expect(message, '请解压下载的包并替换现有安装');
  });
}

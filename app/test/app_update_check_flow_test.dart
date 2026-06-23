import 'dart:io';

import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/domain/use_cases/download_app_update.dart';
import 'package:comic_book_maker/domain/use_cases/install_app_update.dart';
import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';
import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/providers/app_update_providers.dart';
import 'package:comic_book_maker/providers/auto_update_provider.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository(this.release, {this.onDownload});

  final AppUpdateRelease release;
  final Future<String> Function(
    AppUpdateRelease release, {
    required String directory,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  })? onDownload;

  @override
  Future<AppUpdateRelease> fetchLatestRelease() async => release;

  @override
  Future<String> downloadReleaseAsset(
    AppUpdateRelease release, {
    required String directory,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) {
    if (onDownload != null) {
      return onDownload!(release, directory: directory, onProgress: onProgress);
    }
    throw UnimplementedError();
  }
}

void main() {
  late InMemoryCoreGateway gateway;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Comic Book Maker',
      packageName: 'com.example.comic_book_maker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    resetDesktopWindowConfigForTesting();
    desktopWindowConfig = DesktopWindowConfig.disabled;
    gateway = InMemoryCoreGateway.emptyLibrary();
    appRouter.go(AppRoutes.settings);
    resetAppUpdatePlatformOverride();
    appUpdatePlatformOverride = TargetPlatform.windows;
    // 本文件只测手动检查；关闭自动更新以免与启动检查抢弹窗。
    SharedPreferences.setMockInitialValues({
      autoUpdateStorageKey: false,
    });
  });

  tearDown(resetAppUpdatePlatformOverride);

  Future<void> pumpSettings(
    WidgetTester tester, {
    required AppUpdateRepository repository,
    List extraOverrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coreGatewayProvider.overrideWithValue(gateway),
          appUpdateRepositoryProvider.overrideWithValue(repository),
          ...extraOverrides,
        ],
        child: const ComicBookMakerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('manual check shows update dialog when newer release exists', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      repository: _FakeAppUpdateRepository(
        AppUpdateRelease(
          version: '2.0.0',
          tagName: 'v2.0.0',
          releaseNotes: '- 修复若干问题',
          releasePageUrl:
              'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.0.0',
          downloadUrl: 'https://example.com/win.exe',
          publishedAt: DateTime.utc(2026, 6, 18),
        ),
      ),
    );

    await tester.tap(find.text('检查更新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('发现新版本 2.0.0'), findsOneWidget);
    expect(find.text('- 修复若干问题'), findsOneWidget);
    expect(find.text('发布时间: 2026-06-18'), findsOneWidget);
    expect(find.text('稍后提醒'), findsOneWidget);
    expect(find.text('查看更新'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
  });

  testWidgets('manual check shows snackbar when already up to date', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      repository: _FakeAppUpdateRepository(
        const AppUpdateRelease(
          version: '1.0.0',
          tagName: 'v1.0.0',
          releaseNotes: '',
          releasePageUrl:
              'https://github.com/Zoti321/comic-book-maker/releases/tag/v1.0.0',
          downloadUrl: 'https://example.com/win.exe',
        ),
      ),
    );

    await tester.tap(find.text('检查更新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('已是最新版本'), findsOneWidget);
    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('remind later dismisses dialog for current session', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      repository: _FakeAppUpdateRepository(
        const AppUpdateRelease(
          version: '2.0.0',
          tagName: 'v2.0.0',
          releaseNotes: '新功能',
          releasePageUrl:
              'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.0.0',
          downloadUrl: 'https://example.com/win.exe',
        ),
      ),
    );

    final element = tester.element(find.byType(ComicBookMakerApp));
    final container = ProviderScope.containerOf(element);

    await tester.tap(find.text('检查更新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('稍后提醒'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('发现新版本 2.0.0'), findsNothing);
    expect(container.read(appUpdateSessionProvider), isTrue);
  });

  testWidgets('install now opens download progress dialog', (
    tester,
  ) async {
    late Directory tempDir;
    tempDir = Directory.systemTemp.createTempSync('cbm-update-flow-');
    addTearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } on Object {
        // Windows 上文件句柄可能尚未释放。
      }
    });

    const release = AppUpdateRelease(
      version: '2.0.0',
      tagName: 'v2.0.0',
      releaseNotes: '新功能',
      releasePageUrl:
          'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.0.0',
      downloadUrl: 'https://example.com/comic-book-maker-2.0.0-windows-x64-setup.exe',
    );

    Future<String> fakeDownload(
      AppUpdateRelease release, {
      required String directory,
      void Function(int receivedBytes, int? totalBytes)? onProgress,
    }) async {
      onProgress?.call(8, 16);
      final file = File('$directory/setup.exe');
      await file.writeAsBytes(const [1, 2, 3]);
      return file.path;
    }

    await pumpSettings(
      tester,
      repository: _FakeAppUpdateRepository(release, onDownload: fakeDownload),
      extraOverrides: [
        downloadAppUpdateProvider.overrideWithValue(
          DownloadAppUpdate(
            repository: _FakeAppUpdateRepository(release, onDownload: fakeDownload),
            tempDirectory: () async => tempDir,
          ),
        ),
        installAppUpdateProvider.overrideWithValue(
          InstallAppUpdate(
            platform: () => AppUpdateTargetPlatform.windows,
            launchInstaller: (_) async {},
          ),
        ),
      ],
    );

    await tester.tap(find.text('检查更新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('立即更新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('正在下载更新'), findsOneWidget);
    expect(find.text('已下载 0.0 MB / 0.0 MB'), findsOneWidget);
  });
}

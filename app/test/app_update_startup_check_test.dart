import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
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
  _FakeAppUpdateRepository(this.release, {this.throwOnFetch = false});

  final AppUpdateRelease release;
  final bool throwOnFetch;

  @override
  Future<AppUpdateRelease> fetchLatestRelease() async {
    if (throwOnFetch) {
      throw const AppUpdateRepositoryException('network down');
    }
    return release;
  }

  @override
  Future<String> downloadReleaseAsset(
    AppUpdateRelease release, {
    required String directory,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) {
    throw UnimplementedError();
  }
}

const _newerRelease = AppUpdateRelease(
  version: '2.0.0',
  tagName: 'v2.0.0',
  releaseNotes: '启动检查新版本',
  releasePageUrl:
      'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.0.0',
  downloadUrl: 'https://example.com/win.exe',
);

void main() {
  late InMemoryCoreGateway gateway;

  setUpAll(() {
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
    appRouter.go(AppRoutes.projects);
    resetAppUpdatePlatformOverride();
    appUpdatePlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(resetAppUpdatePlatformOverride);

  Future<void> pumpApp(
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
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows update dialog on cold start when auto update is enabled', (
    tester,
  ) async {
    await pumpApp(tester, repository: _FakeAppUpdateRepository(_newerRelease));

    expect(find.text('发现新版本 2.0.0'), findsOneWidget);
    expect(find.text('启动检查新版本'), findsOneWidget);
  });

  testWidgets('does not check on startup when auto update is disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      autoUpdateStorageKey: false,
    });

    await pumpApp(tester, repository: _FakeAppUpdateRepository(_newerRelease));

    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('does not show dialog when session was dismissed', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: _FakeAppUpdateRepository(_newerRelease),
      extraOverrides: [
        appUpdateSessionProvider.overrideWithValue(true),
      ],
    );

    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('silently ignores startup check failures', (tester) async {
    await pumpApp(
      tester,
      repository: _FakeAppUpdateRepository(_newerRelease, throwOnFetch: true),
    );

    expect(find.text('发现新版本'), findsNothing);
    expect(find.text('检查更新失败'), findsNothing);
  });

  testWidgets('does not check on startup on mobile platforms', (tester) async {
    appUpdatePlatformOverride = TargetPlatform.android;

    await pumpApp(tester, repository: _FakeAppUpdateRepository(_newerRelease));

    expect(find.text('发现新版本'), findsNothing);
  });
}

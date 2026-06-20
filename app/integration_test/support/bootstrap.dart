import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:comic_book_maker/bootstrap/comic_book_maker_bootstrap.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/core/design_system/app_toast_controller.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _desktopViewport = Size(1280, 800);

/// 集成测试 harness：临时目录、真 Core 启动与桌面视口。
class IntegrationTestHarness {
  IntegrationTestHarness._({
    required this.appDataDir,
    this.exportDir,
  });

  final Directory appDataDir;
  final Directory? exportDir;

  static Future<IntegrationTestHarness> create({Directory? exportDir}) async {
    final appDataDir =
        await Directory.systemTemp.createTemp('cbm-integration-app-');
    return IntegrationTestHarness._(
      appDataDir: appDataDir,
      exportDir: exportDir,
    );
  }

  Future<void> bootstrap() async {
    resetDesktopWindowConfigForTesting();
    appRouter.go(AppRoutes.projects);
    await bootstrapComicBookMaker(
      appDataDir: appDataDir.path,
      skipDesktopWindowSetup: true,
    );
  }

  Future<void> dispose() async {
    AppToastController.debugReset();
    resetLibraryForTesting();
    if (appDataDir.existsSync()) {
      await appDataDir.delete(recursive: true);
    }
    if (exportDir != null && exportDir!.existsSync()) {
      await exportDir!.delete(recursive: true);
    }
  }

  Future<void> configureViewport(WidgetTester tester) async {
    tester.view.physicalSize = _desktopViewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await configureViewport(tester);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// 等待向导创建完成（项目出现在库中，或出现成功/失败 SnackBar）。
Future<void> pumpUntilProjectCreated(
  WidgetTester tester, {
  required String catalogTitle,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));

    if (find.textContaining('创建失败').evaluate().isNotEmpty) {
      fail('向导创建失败：${find.textContaining('创建失败')}');
    }
    if (find.textContaining('已创建').evaluate().isNotEmpty) {
      return;
    }
    if (listProjects().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
    if (find.text(catalogTitle).evaluate().isNotEmpty &&
        find.byType(AnimatedTextKit).evaluate().isEmpty) {
      return;
    }
  }

  fail(
    '等待项目「$catalogTitle」创建超时（库内项目数：${listProjects().length}）',
  );
}

void integrationTestSetUpAll() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ensureRustLibInitialized();
  });
}

Future<IntegrationTestHarness> launchEmptyLibrary(WidgetTester tester) async {
  final harness = await IntegrationTestHarness.create();
  addTearDown(harness.dispose);
  await harness.bootstrap();
  await harness.pumpApp(tester);
  return harness;
}

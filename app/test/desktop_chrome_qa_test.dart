import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_shell.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/core_gateway_scope.dart';

/// Issue 04：三桌面 chrome 目视验收的可自动化回归项。
void main() {
  const windowManagerChannel = MethodChannel('window_manager');
  late InMemoryCoreGateway gateway;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    resetDesktopWindowConfigForTesting();
    gateway = InMemoryCoreGateway.emptyLibrary();
    appRouter.go(AppRoutes.projects);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowManagerChannel, (call) async {
      switch (call.method) {
        case 'isMaximized':
          return false;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowManagerChannel, null);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    required DesktopWindowConfig config,
    Size surfaceSize = const Size(1280, 800),
  }) async {
    desktopWindowConfig = config;

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      coreGatewayScope(
        gateway: gateway,
        child: const ComicBookMakerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('chrome enabled', () {
    setUp(() {
      desktopWindowConfig = const DesktopWindowConfig(chromeEnabled: true);
    });

    testWidgets('shows split chrome and library shell at desktop width', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, config: const DesktopWindowConfig(chromeEnabled: true));

      expect(find.byKey(DesktopShell.captionSlotKey), findsNothing);
      expect(find.byKey(AppShellSidebarChromeRow.slotKey), findsOneWidget);
      expect(find.byKey(AppShellContentChromeRow.slotKey), findsOneWidget);
      expect(find.byType(WindowCaption), findsOneWidget);
      expect(find.byType(WindowCaptionButton), findsWidgets);
      expect(find.text('Comic Book Maker'), findsNothing);
      expect(find.text('漫画库'), findsOneWidget);
      expect(find.text('项目'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('project editor keeps business AppBar below window caption', (
      WidgetTester tester,
    ) async {
      gateway = InMemoryCoreGateway.editorProject();
      await pumpApp(tester, config: const DesktopWindowConfig(chromeEnabled: true));

      final project = gateway.projects.single;
      appRouter.go(AppRoutes.projectEditorPath(project.id), extra: project);
      await tester.pumpAndSettle();

      expect(find.byKey(AppShellFullWidthChromeRow.slotKey), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('导出'), findsOneWidget);
      expect(find.text('图片'), findsOneWidget);
      expect(find.text('元数据'), findsOneWidget);
    });

    testWidgets('caption uses solid background token', (WidgetTester tester) async {
      await pumpApp(tester, config: const DesktopWindowConfig(chromeEnabled: true));

      final caption = tester.widget<WindowCaption>(find.byType(WindowCaption));
      expect(caption.backgroundColor, isNotNull);
      expect(caption.backgroundColor!.a, 1.0);
    });
  });

  group('chrome disabled fallback', () {
    testWidgets('hides caption slot and keeps library usable', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, config: DesktopWindowConfig.disabled);

      expect(find.byKey(AppShellSidebarChromeRow.slotKey), findsNothing);
      expect(find.byType(WindowCaption), findsNothing);
      expect(find.text('漫画库'), findsOneWidget);
      expect(find.text('还没有项目'), findsOneWidget);
    });
  });
}

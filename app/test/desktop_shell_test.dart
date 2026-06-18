import 'package:comic_book_maker/ui/core/design_system/desktop_window_caption.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_shell.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  const windowManagerChannel = MethodChannel('window_manager');

  setUp(() {
    resetDesktopWindowConfigForTesting();
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

  Future<void> pumpShell(
    WidgetTester tester, {
    required DesktopWindowConfig config,
    required Widget child,
    Size surfaceSize = const Size(1280, 800),
    Widget? captionOverride,
    DesktopShellFrameBuilder? frameBuilderOverride,
  }) async {
    desktopWindowConfig = config;

    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DesktopShell(
          captionOverride: captionOverride,
          frameBuilderOverride: frameBuilderOverride,
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('compact width adds full-width chrome row when chrome is enabled', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      config: const DesktopWindowConfig(chromeEnabled: true),
      child: const Scaffold(body: Text('应用正文')),
      surfaceSize: const Size(400, 800),
      frameBuilderOverride: (child) => child,
    );

    expect(find.byKey(AppShellFullWidthChromeRow.slotKey), findsOneWidget);
    expect(find.text('应用正文'), findsOneWidget);
  });

  testWidgets('wide width passes chrome handling to AppShell child', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      config: const DesktopWindowConfig(chromeEnabled: true),
      child: const Scaffold(body: Text('编辑页')),
      frameBuilderOverride: (child) => child,
    );

    expect(find.byKey(AppShellFullWidthChromeRow.slotKey), findsNothing);
    expect(find.text('编辑页'), findsOneWidget);
  });

  testWidgets('compact chrome override slot when captionOverride is set', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      config: const DesktopWindowConfig(chromeEnabled: true),
      child: const Scaffold(body: Text('应用正文')),
      surfaceSize: const Size(400, 800),
      captionOverride: const Text('窗口顶栏'),
      frameBuilderOverride: (child) => child,
    );

    expect(find.byKey(DesktopShell.captionSlotKey), findsOneWidget);
    expect(find.text('窗口顶栏'), findsOneWidget);
    expect(find.text('应用正文'), findsOneWidget);
  });

  testWidgets('passes through child without caption when chrome is disabled', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      config: DesktopWindowConfig.disabled,
      child: const Scaffold(body: Text('应用正文')),
      captionOverride: const Text('窗口顶栏'),
      frameBuilderOverride: (child) => child,
    );

    expect(find.byKey(DesktopShell.captionSlotKey), findsNothing);
    expect(find.text('窗口顶栏'), findsNothing);
    expect(find.text('应用正文'), findsOneWidget);
  });

  testWidgets('DesktopWindowCaption uses content surface background',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: DesktopWindowCaption(),
        ),
      ),
    );
    await tester.pump();

    final windowCaption = tester.widget<WindowCaption>(find.byType(WindowCaption));
    expect(
      windowCaption.backgroundColor,
      AppShellChrome.contentBackground(AppTheme.light().colorScheme),
    );
    expect(find.text('Comic Book Maker'), findsNothing);
  });
}

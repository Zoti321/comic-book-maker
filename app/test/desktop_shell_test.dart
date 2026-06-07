import 'package:comic_book_maker/ui/core/design_system/desktop_window_caption.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_shell.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
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
    Widget? captionOverride,
    DesktopShellFrameBuilder? frameBuilderOverride,
  }) async {
    desktopWindowConfig = config;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DesktopShell(
          captionOverride: captionOverride,
          frameBuilderOverride: frameBuilderOverride,
          child: const Scaffold(body: Text('应用正文')),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders caption slot and body when chrome is enabled', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      config: const DesktopWindowConfig(chromeEnabled: true),
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
      captionOverride: const Text('窗口顶栏'),
      frameBuilderOverride: (child) => child,
    );

    expect(find.byKey(DesktopShell.captionSlotKey), findsNothing);
    expect(find.text('窗口顶栏'), findsNothing);
    expect(find.text('应用正文'), findsOneWidget);
  });

  testWidgets('DesktopWindowCaption uses shell chrome surface background',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: DesktopWindowCaption(title: 'Comic Book Maker'),
        ),
      ),
    );
    await tester.pump();

    final windowCaption = tester.widget<WindowCaption>(find.byType(WindowCaption));
    expect(
      windowCaption.backgroundColor,
      AppTheme.light().colorScheme.surface,
    );
    expect(find.text('Comic Book Maker'), findsOneWidget);
  });

  testWidgets('split chrome aligns caption lead with sidebar width at desktop',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpShell(
      tester,
      config: const DesktopWindowConfig(chromeEnabled: true),
      frameBuilderOverride: (child) => child,
    );

    expect(find.byKey(DesktopShellChromeLead.keySlot), findsOneWidget);
    expect(find.text('Comic Book Maker'), findsOneWidget);
  });
}

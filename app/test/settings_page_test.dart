import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/providers/auto_update_provider.dart';
import 'package:comic_book_maker/providers/theme_mode_provider.dart' hide ThemeMode;
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/core_gateway_scope.dart';

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
    SharedPreferences.setMockInitialValues({});
    resetDesktopWindowConfigForTesting();
    desktopWindowConfig = DesktopWindowConfig.disabled;
    gateway = InMemoryCoreGateway.emptyLibrary();
    appRouter.go(AppRoutes.settings);
    resetAppUpdatePlatformOverride();
    appUpdatePlatformOverride = TargetPlatform.windows;
  });

  tearDown(resetAppUpdatePlatformOverride);

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Size viewport,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      coreGatewayScope(
        gateway: gateway,
        child: const ComicBookMakerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows export settings section at desktop width', (tester) async {
    await pumpSettings(tester, viewport: const Size(1280, 800));

    expect(find.text('设置'), findsWidgets);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    await tester.tap(find.text('主题模式'));
    await tester.pumpAndSettle();
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);
    expect(find.text('应用偏好与导出默认值'), findsNothing);
    expect(find.text('默认导出目录'), findsOneWidget);
    expect(find.text('未设置'), findsOneWidget);
    expect(find.text('选择目录'), findsNothing);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('shows app update section with current version on desktop', (
    tester,
  ) async {
    await pumpSettings(tester, viewport: const Size(1280, 800));

    expect(find.text('应用更新'), findsOneWidget);
    expect(find.text('自动更新'), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('当前版本 1.0.0'), findsOneWidget);

    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.length, 1);
    expect(switches.first.value, isTrue);
    expect(switches.first.onChanged, isNotNull);
  });

  testWidgets('auto update preference persists across restart on desktop', (
    tester,
  ) async {
    await pumpSettings(tester, viewport: const Size(1280, 800));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(autoUpdateStorageKey), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpSettings(tester, viewport: const Size(1280, 800));

    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.single.value, isFalse);
  });

  testWidgets('app update controls are enabled on android', (
    tester,
  ) async {
    appUpdatePlatformOverride = TargetPlatform.android;

    await pumpSettings(tester, viewport: const Size(400, 800));

    expect(find.text('应用更新'), findsOneWidget);
    expect(find.text('当前版本 1.0.0'), findsOneWidget);

    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.length, 1);
    expect(switches.first.value, isTrue);
    expect(switches.first.onChanged, isNotNull);
  });

  testWidgets('app update controls remain disabled on ios', (
    tester,
  ) async {
    appUpdatePlatformOverride = TargetPlatform.iOS;

    await pumpSettings(tester, viewport: const Size(400, 800));

    expect(find.text('应用更新'), findsOneWidget);
    expect(find.text('当前版本 1.0.0'), findsOneWidget);

    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.length, 1);
    expect(switches.first.value, isFalse);
    expect(switches.first.onChanged, isNull);
  });

  testWidgets('export controls remain usable at compact width', (tester) async {
    await pumpSettings(tester, viewport: const Size(400, 800));

    expect(find.text('未设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme mode selection persists across restart', (tester) async {
    await pumpSettings(tester, viewport: const Size(1280, 800));

    await tester.tap(find.text('主题模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themeModeStorageKey), 'dark');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpSettings(tester, viewport: const Size(1280, 800));

    expect(find.text('深色'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
  });
}

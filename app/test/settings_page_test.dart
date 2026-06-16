import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/providers/theme_mode_provider.dart' hide ThemeMode;
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/core_gateway_scope.dart';

void main() {
  late InMemoryCoreGateway gateway;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    resetDesktopWindowConfigForTesting();
    desktopWindowConfig = DesktopWindowConfig.disabled;
    gateway = InMemoryCoreGateway.emptyLibrary();
    appRouter.go(AppRoutes.settings);
  });

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
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);
    expect(find.text('应用偏好与导出默认值'), findsNothing);
    expect(find.text('默认导出目录'), findsOneWidget);
    expect(find.text('未设置'), findsOneWidget);
    expect(find.text('选择目录'), findsNothing);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('export controls remain usable at compact width', (tester) async {
    await pumpSettings(tester, viewport: const Size(400, 800));

    expect(find.text('未设置'), findsOneWidget);
    expect(find.byType(IconButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme mode selection persists across restart', (tester) async {
    await pumpSettings(tester, viewport: const Size(1280, 800));

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themeModeStorageKey), 'dark');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpSettings(tester, viewport: const Size(1280, 800));

    final segmented = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(segmented.selected, {ThemeMode.dark});
  });
}

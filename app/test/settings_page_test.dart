import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/design_system/app_icon_button.dart';
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
    expect(find.text('应用偏好与导出默认值'), findsNothing);
    expect(find.text('默认导出目录'), findsOneWidget);
    expect(find.text('未设置'), findsOneWidget);
    expect(find.text('选择目录'), findsNothing);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('export controls remain usable at compact width', (tester) async {
    await pumpSettings(tester, viewport: const Size(400, 800));

    expect(find.text('未设置'), findsOneWidget);
    expect(find.byType(AppIconButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/mobile_app_nav.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
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
    appRouter.go(AppRoutes.projects);
  });

  void _setViewport(WidgetTester tester, Size surfaceSize) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size surfaceSize,
    bool settle = true,
  }) async {
    _setViewport(tester, surfaceSize);

    await tester.pumpWidget(
      coreGatewayScope(
        gateway: gateway,
        child: const ComicBookMakerApp(),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('compact width shows bottom navigation', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(400, 800), settle: false);

    expect(find.byType(Sidebar), findsNothing);
    expect(find.byType(MobileAppNav), findsOneWidget);
    expect(find.text('漫画库'), findsOneWidget);
  });

  testWidgets('medium width shows sidebar navigation', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(900, 800));

    expect(find.byType(Sidebar), findsOneWidget);
    expect(find.byType(MobileAppNav), findsNothing);
    expect(find.text('漫画库'), findsOneWidget);
  });

  testWidgets('sidebar navigation switches to settings branch', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(1280, 800));

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();

    expect(find.text('导出'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('漫画库'), findsNothing);
  });

  testWidgets('bottom navigation switches to settings on compact', (
    tester,
  ) async {
    await pumpApp(tester, surfaceSize: const Size(400, 800), settle: false);

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('导出'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('720px width has no layout overflow with sidebar', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(720, 600));

    expect(find.byType(Sidebar), findsOneWidget);
    expect(tester.takeException(), isNull);

    final sidebar = tester.getSize(find.byType(Sidebar));
    expect(sidebar.width, AppLayout.sidebarWidth);
    expect(find.text('漫画库'), findsOneWidget);
  });
}

import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_bar.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_rail.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
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

  void setViewport(WidgetTester tester, Size surfaceSize) {
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
    setViewport(tester, surfaceSize);

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

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('漫画库'), findsOneWidget);
  });

  testWidgets('minimum width 360px shows bottom navigation without overflow', (
    tester,
  ) async {
    await pumpApp(tester, surfaceSize: const Size(360, 640), settle: false);

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.text('漫画库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium width shows navigation rail', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(900, 800));

    expect(find.byType(AppNavigationRail), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(AppNavigationBar), findsNothing);
    expect(find.text('漫画库'), findsOneWidget);
  });

  testWidgets('navigation rail switches to settings branch', (tester) async {
    await pumpApp(tester, surfaceSize: const Size(1280, 800));

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();

    expect(find.text('默认导出目录'), findsOneWidget);
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

    expect(find.text('默认导出目录'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('720px width has no layout overflow with navigation rail', (
    tester,
  ) async {
    await pumpApp(tester, surfaceSize: const Size(720, 600));

    expect(find.byType(AppNavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);

    final rail = tester.getSize(find.byType(AppNavigationRail));
    expect(rail.width, AppLayout.sidebarWidth);
    expect(find.text('漫画库'), findsOneWidget);
  });
}

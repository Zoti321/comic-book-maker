import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/frb/rust_fake.dart';
import 'support/provider/core_gateway_scope.dart';

void main() {
  rustTestSetUpAll();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    resetDesktopWindowConfigForTesting();
    desktopWindowConfig = DesktopWindowConfig.disabled;
    appRouter.go(AppRoutes.projects);
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      coreGatewayScope(
        gateway: InMemoryCoreGateway.emptyLibrary(),
        child: const ComicBookMakerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('runCreateProjectWizard routing', () {
    testWidgets('compact viewport opens full page instead of dialog', (
      tester,
    ) async {
      await pumpLibrary(tester, surfaceSize: const Size(400, 800));

      expect(find.byType(AppNavigationBar), findsOneWidget);

      await tester.tap(find.byTooltip('新建项目'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('新建项目'), findsWidgets);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建'), findsOneWidget);
    });

    testWidgets('wide viewport opens dialog instead of full page route', (
      tester,
    ) async {
      await pumpLibrary(tester, surfaceSize: const Size(1280, 900));

      expect(find.byType(AppNavigationBar), findsNothing);

      await tester.tap(find.byTooltip('新建项目'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      expect(find.widgetWithText(FilledButton, '创建'), findsOneWidget);
    });
  });
}

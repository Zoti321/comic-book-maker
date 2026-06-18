import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
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
    desktopWindowConfig = const DesktopWindowConfig(chromeEnabled: true);
    gateway = InMemoryCoreGateway.editorProject();
    appRouter.go(AppRoutes.projects);
  });

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
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

  testWidgets('project editor survives wide-to-narrow resize without losing route extra', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1280, 800));

    final project = gateway.projects.single;
    appRouter.go(AppRoutes.projectEditorPath(project.id), extra: project);
    await tester.pumpAndSettle();

    expect(find.text('图片'), findsOneWidget);
    expect(find.text('缺少项目信息'), findsNothing);

    await pumpAtSize(tester, const Size(600, 800));
    await tester.pumpAndSettle();

    expect(find.text('缺少项目信息'), findsNothing);
    expect(find.text('图片'), findsOneWidget);
    expect(find.byKey(AppShellFullWidthChromeRow.slotKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

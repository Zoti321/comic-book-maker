import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/project_editor/pages/pages_panel.dart';
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
    gateway = InMemoryCoreGateway.editorProject();
    appRouter.go(AppRoutes.projects);
  });

  Future<void> openEditor(
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

    final project = gateway.projects.single;
    appRouter.go(AppRoutes.projectEditorPath(project.id), extra: project);
    await tester.pumpAndSettle();
  }

  testWidgets('compact editor shows icon toolbar and stacked tab row', (
    tester,
  ) async {
    await openEditor(tester, viewport: const Size(400, 800));

    expect(find.text('导出'), findsNothing);
    expect(find.byTooltip('导出为 漫画压缩包'), findsOneWidget);
    expect(find.text('图片'), findsOneWidget);
    expect(find.text('元数据'), findsOneWidget);
    expect(find.byTooltip('项目属性'), findsOneWidget);
    expect(find.text('添加页面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metadata tab is reachable at compact width', (tester) async {
    await openEditor(tester, viewport: const Size(400, 800));

    await tester.tap(find.text('元数据'));
    await tester.pumpAndSettle();

    expect(find.text('元数据'), findsWidgets);
    expect(find.text('添加页面'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('thumbnail cross axis count adapts to available space', () {
    expect(pageThumbnailCrossAxisCount(360), 3);
    expect(pageThumbnailCrossAxisCount(900), 8);
    expect(pageThumbnailCrossAxisCount(1200), 8);
    expect(pageThumbnailCrossAxisCount(0), 2);
  });
}

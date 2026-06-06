import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/main.dart';
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
    gateway = InMemoryCoreGateway.emptyLibrary();
    appRouter.go(AppRoutes.projects);
  });

  group('library', () {
    testWidgets('lists projects when catalog is non-empty', (
      WidgetTester tester,
    ) async {
      gateway.projects.add(
        ProjectSummary(
          id: 'lib-1',
          title: '库内项目',
          updatedAtMs: 1,
          coverThumbnailPath: null,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        coreGatewayScope(
          gateway: gateway,
          child: const ComicBookMakerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没有项目'), findsNothing);
      expect(find.text('库内项目'), findsOneWidget);
      expect(find.text('1 个项目 · 按最近打开排序'), findsOneWidget);
    });

    testWidgets('empty state at desktop width', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        coreGatewayScope(
          gateway: gateway,
          child: const ComicBookMakerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comic Book Maker'), findsOneWidget);
      expect(find.text('漫画库'), findsOneWidget);
      expect(find.text('还没有项目'), findsOneWidget);
      expect(find.text('新建项目'), findsWidgets);
      expect(find.text('导入漫画'), findsNothing);
      expect(find.text('设置'), findsOneWidget);
    });
  });

  group('project editor', () {
    setUp(() {
      gateway = InMemoryCoreGateway.editorProject();
    });

    testWidgets('shows image and metadata tabs', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      expect(find.text('测试项目'), findsOneWidget);
      expect(find.text('导出'), findsOneWidget);
      expect(find.text('添加图片'), findsOneWidget);
      expect(find.text('图片'), findsOneWidget);
      expect(find.text('元数据'), findsOneWidget);
      expect(find.byTooltip('项目属性'), findsOneWidget);
      expect(find.text('0 页'), findsNothing);
      expect(find.text('1 页'), findsNWidgets(2));
      expect(find.text('添加页面'), findsOneWidget);

      await tester.tap(find.text('元数据'));
      await tester.pumpAndSettle();

      expect(find.text('ComicInfo'), findsWidgets);
      expect(find.text('添加页面'), findsNothing);
    });
  });

  group('mobile shell', () {
    testWidgets('bottom nav opens settings', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        coreGatewayScope(
          gateway: gateway,
          child: const ComicBookMakerApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('设置'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('导出'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
    });
  });
}

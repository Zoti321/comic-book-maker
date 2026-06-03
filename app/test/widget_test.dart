import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/router/app_router.dart';
import 'package:comic_book_maker/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/rust_fake.dart';

void main() {
  late FakeRustLibApi fake;

  setUpAll(() {
    fake = FakeRustLibApi.emptyLibrary();
    initRustTestFake(fake);
  });

  setUp(() {
    fake.projects.clear();
    fake.metadataByProjectId.clear();
    appRouter.go(AppRoutes.projects);
  });

  group('library', () {
    testWidgets('empty state at desktop width', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: ComicBookMakerApp()),
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
      final editor = FakeRustLibApi.editorProject();
      fake.projects.addAll(editor.projects);
      fake.metadataByProjectId.addAll(editor.metadataByProjectId);
    });

    testWidgets('shows image and metadata tabs', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: ComicBookMakerApp()),
      );
      await tester.pumpAndSettle();

      final project = fake.projects.single;
      appRouter.go(AppRoutes.projectEditorPath(project.id), extra: project);
      await tester.pumpAndSettle();

      expect(find.text('测试项目'), findsOneWidget);
      expect(find.text('导出 CBZ'), findsOneWidget);
      expect(find.text('添加图片'), findsOneWidget);
      expect(find.text('图片'), findsOneWidget);
      expect(find.text('元数据'), findsOneWidget);
      expect(find.byTooltip('项目属性'), findsOneWidget);
      expect(find.text('0 页'), findsOneWidget);
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
        const ProviderScope(child: ComicBookMakerApp()),
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

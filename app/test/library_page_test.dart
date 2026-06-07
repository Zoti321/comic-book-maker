import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/library/library_page.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/core_gateway_scope.dart';

void main() {
  late InMemoryCoreGateway gateway;

  setUp(() {
    gateway = InMemoryCoreGateway.emptyLibrary();
  });

  Future<void> pumpLibrary(
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
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty library shows guidance header and empty state', (
    tester,
  ) async {
    await pumpLibrary(tester, viewport: const Size(1280, 800));

    expect(find.text('漫画库'), findsOneWidget);
    expect(find.text('创建或导入你的第一本漫画'), findsOneWidget);
    expect(find.text('还没有项目'), findsOneWidget);
    expect(find.text('新建项目'), findsWidgets);
    expect(find.byType(ProjectCard), findsNothing);
  });

  testWidgets('non-empty library lists projects with count subtitle', (
    tester,
  ) async {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '我的漫画',
        updatedAtMs: 1_700_000_000_000,
        coverThumbnailPath: null,
      ),
    );

    await pumpLibrary(tester, viewport: const Size(1280, 800));

    expect(find.text('1 个项目 · 按最近打开排序'), findsOneWidget);
    expect(find.text('我的漫画'), findsOneWidget);
    expect(find.byType(ProjectCard), findsOneWidget);
    expect(find.text('还没有项目'), findsNothing);
  });

  testWidgets('compact width uses shorter create label without overflow', (
    tester,
  ) async {
    await pumpLibrary(tester, viewport: const Size(400, 800));

    expect(find.text('新建'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('720px sidebar layout shows grid without overflow', (
    tester,
  ) async {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '窄屏项目',
        updatedAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    await pumpLibrary(tester, viewport: const Size(720, 600));

    expect(find.byType(ProjectCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

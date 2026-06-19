import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/library/library_page.dart';
import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_sort_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/core_gateway_scope.dart';

void main() {
  late InMemoryCoreGateway gateway;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    await tester.pumpAndSettle(const Duration(milliseconds: 800));
  }

  testWidgets('empty library shows guidance header and empty state', (
    tester,
  ) async {
    await pumpLibrary(tester, viewport: const Size(1280, 800));

    expect(find.text('漫画库'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.byType(Badge), findsOneWidget);
    expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    expect(find.byType(AnimatedTextKit), findsOneWidget);
    expect(find.text('新建项目'), findsWidgets);
    expect(find.byIcon(Icons.add), findsWidgets);
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
        createdAtMs: 1_700_000_000_000,
        coverThumbnailPath: null,
      ),
    );

    await pumpLibrary(tester, viewport: const Size(1280, 800));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('我的漫画'), findsOneWidget);
    expect(find.byType(ProjectCard), findsOneWidget);
    expect(find.text('还没有项目'), findsNothing);
  });

  testWidgets('compact width uses icon-only header create without overflow', (
    tester,
  ) async {
    await pumpLibrary(tester, viewport: const Size(400, 800));

    expect(find.byIcon(Icons.add), findsWidgets);
    expect(find.text('新建项目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('minimum width 360px shows library without overflow', (
    tester,
  ) async {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '最小宽度项目',
        updatedAtMs: 1,
        createdAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    await pumpLibrary(tester, viewport: const Size(360, 640));

    expect(find.text('漫画库'), findsOneWidget);
    expect(find.byType(ProjectCard), findsOneWidget);
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
        createdAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    await pumpLibrary(tester, viewport: const Size(720, 600));

    expect(find.byType(ProjectCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settled grid does not keep Animate wrappers', (tester) async {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '首次入场',
        updatedAtMs: 1,
        createdAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    await pumpLibrary(tester, viewport: const Size(1280, 800));

    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('does not replay grid entrance after sort changes', (
    tester,
  ) async {
    gateway.projects.addAll([
      ProjectSummary(
        id: 'p1',
        title: '甲',
        updatedAtMs: 2,
        createdAtMs: 2,
        coverThumbnailPath: null,
      ),
      ProjectSummary(
        id: 'p2',
        title: '乙',
        updatedAtMs: 1,
        createdAtMs: 1,
        coverThumbnailPath: null,
      ),
    ]);

    await pumpLibrary(tester, viewport: const Size(1280, 800));
    expect(find.byType(Animate), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPage)),
    );
    await container.read(librarySortProvider.notifier).setSort(
          const LibrarySortState(
            field: LibrarySortField.title,
            ascending: true,
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Animate), findsNothing);
    expect(find.text('甲'), findsOneWidget);
    expect(find.text('乙'), findsOneWidget);
  });
}

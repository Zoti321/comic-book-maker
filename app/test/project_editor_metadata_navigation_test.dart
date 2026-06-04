import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frb/rust_fake.dart';

Future<void> _openProjectEditor(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    const ProviderScope(child: ComicBookMakerApp()),
  );
  await tester.pumpAndSettle();

  final project = fake.projects.single;
  appRouter.go(AppRoutes.projectEditorPath(project.id), extra: project);
  await tester.pumpAndSettle();

  await tester.tap(find.text('元数据'));
  await tester.pumpAndSettle();
}

late FakeRustLibApi fake;

void main() {
  setUpAll(() {
    fake = FakeRustLibApi.editorProject();
    initRustTestFake(fake);
  });

  setUp(() {
    fake.projects.clear();
    fake.projects.addAll(FakeRustLibApi.editorProject().projects);
    fake.metadataByProjectId.clear();
    fake.metadataByProjectId.addAll(
      FakeRustLibApi.editorProject().metadataByProjectId,
    );
    fake.pages.clear();
    fake.pages.addAll(FakeRustLibApi.editorProject().pages);
    fake.defaultSettings = FakeRustLibApi.editorProject().defaultSettings;
    fake.metadataUpdateCallCount = 0;
    fake.nextMetadataUpdateError = null;
    fake.failMetadataUpdates = false;
    appRouter.go(AppRoutes.projects);
  });

  testWidgets('flushes pending metadata when switching tabs quickly', (
    tester,
  ) async {
    await _openProjectEditor(tester);

    await tester.enterText(find.byType(TextFormField).last, '7');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, greaterThanOrEqualTo(1));
    expect(fake.metadataByProjectId['p1']?.volume, '7');
    expect(find.text('添加页面'), findsOneWidget);
    expect(find.text('放弃未保存'), findsNothing);

    await tester.tap(find.text('元数据'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField).last, findsOneWidget);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).last).controller?.text, '7');
  });

  testWidgets('blocks tab switch when metadata validation fails', (
    tester,
  ) async {
    await _openProjectEditor(tester);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 0);
    expect(find.text('必填'), findsOneWidget);
    expect(find.text('ComicInfo'), findsWidgets);
    expect(find.text('添加页面'), findsNothing);
  });

  testWidgets('blocks tab switch when metadata save fails', (tester) async {
    await _openProjectEditor(tester);

    fake.failMetadataUpdates = true;

    await tester.enterText(find.byType(TextFormField).last, '8');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, 1);
    expect(find.textContaining('保存失败'), findsOneWidget);

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(find.text('ComicInfo'), findsWidgets);
    expect(find.text('添加页面'), findsNothing);
    expect(find.textContaining('保存失败'), findsOneWidget);
  });

  testWidgets('flushes pending metadata before export', (tester) async {
    await _openProjectEditor(tester);

    await tester.enterText(find.byType(TextFormField).last, '55');
    await tester.pump(const Duration(milliseconds: 100));

    expect(fake.metadataUpdateCallCount, 0);

    await tester.tap(find.text('导出 CBZ'));
    await tester.pumpAndSettle();

    expect(fake.metadataUpdateCallCount, greaterThanOrEqualTo(1));
    expect(fake.metadataByProjectId['p1']?.volume, '55');
    expect(find.text('导出完成'), findsOneWidget);
  });
}

import 'dart:io';

import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/core_gateway_scope.dart';

Future<void> _openProjectEditor(
  WidgetTester tester,
  InMemoryCoreGateway gateway,
) async {
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

  await tester.tap(find.text('元数据'));
  await tester.pumpAndSettle();
}

Future<void> _selectSeriesMetadataSection(WidgetTester tester) async {
  await tester.tap(find.text('系列'));
  await tester.pumpAndSettle();
}

Finder seriesNumberField() => find.byType(TextFormField).at(1);

void main() {
  late InMemoryCoreGateway gateway;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    gateway = InMemoryCoreGateway.editorProject();
    gateway.metadataUpdateCallCount = 0;
    gateway.exportCallCount = 0;
    gateway.nextMetadataUpdateError = null;
    gateway.failMetadataUpdates = false;

    final exportDir = Directory(r'C:\temp\comic-exports');
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }
    final exportFile = File(p.join(exportDir.path, '测试项目.cbz'));
    if (exportFile.existsSync()) {
      exportFile.deleteSync();
    }

    appRouter.go(AppRoutes.projects);
  });

  testWidgets('flushes pending metadata when switching tabs quickly', (
    tester,
  ) async {
    await _openProjectEditor(tester, gateway);

    await _selectSeriesMetadataSection(tester);

    await tester.enterText(seriesNumberField(), '7');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, greaterThanOrEqualTo(1));
    expect(gateway.metadataByProjectId['p1']?.number, '7');
    expect(find.text('添加页面'), findsOneWidget);
    expect(find.text('放弃未保存'), findsNothing);

    await tester.tap(find.text('元数据'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField).at(1), findsOneWidget);
    expect(tester.widget<TextFormField>(seriesNumberField()).controller?.text, '7');
  });

  testWidgets('blocks tab switch when metadata validation fails', (
    tester,
  ) async {
    await _openProjectEditor(tester, gateway);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 0);
    expect(find.text('必填'), findsOneWidget);
    expect(find.text('元数据'), findsWidgets);
    expect(find.text('添加页面'), findsNothing);
  });

  testWidgets('blocks tab switch when metadata save fails', (tester) async {
    await _openProjectEditor(tester, gateway);

    gateway.failMetadataUpdates = true;

    await _selectSeriesMetadataSection(tester);

    await tester.enterText(seriesNumberField(), '8');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gateway.metadataUpdateCallCount, 1);
    expect(find.textContaining('保存失败'), findsOneWidget);

    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    expect(find.text('元数据'), findsWidgets);
    expect(find.text('添加页面'), findsNothing);
    expect(find.textContaining('保存失败'), findsOneWidget);
  });

  testWidgets('flushes pending metadata before export', (tester) async {
    await _openProjectEditor(tester, gateway);

    await _selectSeriesMetadataSection(tester);

    await tester.enterText(seriesNumberField(), '55');
    await tester.pump(const Duration(milliseconds: 100));

    expect(gateway.metadataUpdateCallCount, 0);

    final exportButton = find.text('导出');
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    final overwrite = find.text('覆盖并导出');
    if (overwrite.evaluate().isNotEmpty) {
      await tester.tap(overwrite);
      await tester.pumpAndSettle();
    }

    expect(gateway.metadataUpdateCallCount, greaterThanOrEqualTo(1));
    expect(gateway.metadataByProjectId['p1']?.number, '55');
    expect(gateway.exportCallCount, 1);
    expect(find.text('导出完成'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

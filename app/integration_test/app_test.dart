import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/bootstrap.dart';
import 'support/file_picker_mock.dart';
import 'support/fixtures.dart';
import 'support/seed_project.dart';
import 'support/wizard_actions.dart';

Finder seriesNumberField() => find.byType(TextFormField).at(1);

void main() {
  integrationTestSetUpAll();

  group('smoke', () {
    testWidgets('launches empty library and opens settings', (tester) async {
      await launchEmptyLibrary(tester);

      expect(find.text('漫画库'), findsOneWidget);
      expect(find.byType(AnimatedTextKit), findsOneWidget);
      expect(find.text('新建项目'), findsWidgets);

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('外观'), findsOneWidget);
      expect(find.text('默认导出目录'), findsOneWidget);
    });
  });

  group('editor export', () {
    testWidgets('edits metadata and exports CBZ with real core', (tester) async {
      final exportDir =
          await Directory.systemTemp.createTemp('cbm-integration-export-');
      final harness = await IntegrationTestHarness.create(exportDir: exportDir);
      addTearDown(harness.dispose);

      final seeded = seedTwoPagesProject(
        appDataDir: harness.appDataDir,
        exportDir: exportDir,
      );
      await harness.bootstrap();
      await harness.pumpApp(tester);

      expect(find.text(seeded.catalogTitle), findsOneWidget);

      await tester.tap(find.text(seeded.catalogTitle));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('导出'), findsOneWidget);
      expect(find.text('元数据'), findsOneWidget);

      await tester.tap(find.text('元数据'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('系列'));
      await tester.pumpAndSettle();

      await tester.enterText(seriesNumberField(), '7');
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      await tester.tap(find.text('导出'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('导出完成'), findsOneWidget);

      final exportFile = seeded.expectedExportFile;
      expect(
        exportFile.existsSync(),
        isTrue,
        reason: 'Expected export at ${exportFile.path}',
      );
      expect(exportFile.lengthSync(), greaterThan(0));

      final siblings = exportDir
          .listSync()
          .whereType<File>()
          .where((file) => p.extension(file.path) == '.cbz')
          .toList();
      expect(siblings, hasLength(1));
      expect(p.basename(siblings.single.path), seeded.expectedExportBaseName);
    });
  });

  group('create project wizard', () {
    testWidgets('imports CBZ via wizard and opens editor', (tester) async {
      ensureIntegrationFixtureCbz();
      final fixturePath = integrationFixtureCbzPath();
      final catalogTitle = integrationFixtureCatalogTitle();

      installFilePickerMock(fixturePath);

      final harness = await IntegrationTestHarness.create();
      addTearDown(harness.dispose);
      await harness.bootstrap();
      await harness.pumpApp(tester);

      await tester.tap(find.byTooltip('新建项目'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('新建项目'), findsWidgets);
      expect(find.text('尚未选择'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('导入漫画压缩包'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CBZ：'), findsOneWidget);
      expect(find.textContaining(fixturePath), findsOneWidget);
      expect(find.text('漫画压缩包'), findsOneWidget);

      await tapEnabledCreateButton(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsNothing);

      await pumpUntilProjectCreated(tester, catalogTitle: catalogTitle);

      if (find.text('打开项目').evaluate().isNotEmpty) {
        await tester.tap(find.text('打开项目'));
      } else {
        await tester.tap(find.text(catalogTitle).last);
      }
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('$catalogTitle · 2 页'), findsOneWidget);
      expect(find.text('导出'), findsOneWidget);
      expect(find.text('元数据'), findsOneWidget);
    });
  });
}

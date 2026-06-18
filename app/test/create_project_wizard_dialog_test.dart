import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frb/rust_fake.dart';
import 'support/ui/shell/side_tab_morph_test_harness.dart';

void main() {
  rustTestSetUpAll();

  group('CreateProjectWizardDialog', () {
    testWidgets('disables create until import source is chosen', (
      tester,
    ) async {
      final harness = SideTabMorphTestHarness.withoutChrome(tester);
      await harness.pumpFeatureAt(SideTabMorphTestHarness.wideWidth);

      expect(find.text('新建项目'), findsOneWidget);
      expect(find.text('尚未选择'), findsOneWidget);
      expect(find.text('导入图片'), findsOneWidget);
      expect(find.text('导入漫画压缩包'), findsOneWidget);
      expect(find.text('导入 EPUB'), findsOneWidget);
      expect(find.text('选择要导入的资源（必选）'), findsNothing);

      final createButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '创建'),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('shows export tab after switching side tab', (tester) async {
      final harness = SideTabMorphTestHarness.withoutChrome(tester);
      await harness.pumpFeatureAt(SideTabMorphTestHarness.wideWidth);

      await tester.tap(find.text('导出'));
      await tester.pumpAndSettle();

      expect(find.text('导出格式'), findsOneWidget);
      expect(find.text('使用默认导出目录'), findsOneWidget);
      expect(find.text('导出目录'), findsNothing);
      expect(
        find.text('决定导出文件类型与元数据 Tab 的编辑模型'),
        findsNothing,
      );
    });

    testWidgets('fits content when dialog height is tight', (tester) async {
      final harness = SideTabMorphTestHarness(
        tester,
        height: 600,
      );
      await harness.pumpFeatureAt(800);

      expect(tester.takeException(), isNull);
    });

    testWidgets('compact page shows tab bar with material icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateProjectWizardFeature(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('新建项目'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('导入'), findsWidgets);
      expect(find.text('导出'), findsWidgets);
      expect(find.text('行为'), findsWidgets);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建'), findsOneWidget);
    });
  });
}

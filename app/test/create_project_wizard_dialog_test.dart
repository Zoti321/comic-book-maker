import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frb/rust_fake.dart';

void main() {
  rustTestSetUpAll();

  Future<void> openWizard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: _WizardHost(),
        ),
      ),
    );
    await tester.tap(find.text('打开向导'));
    await tester.pumpAndSettle();
  }

  group('CreateProjectWizardDialog', () {
    testWidgets('disables create until import source is chosen', (
      tester,
    ) async {
      await openWizard(tester);

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
      await openWizard(tester);

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
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: _WizardHost(),
          ),
        ),
      );
      await tester.tap(find.text('打开向导'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

class _WizardHost extends StatelessWidget {
  const _WizardHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => const CreateProjectWizardDialog(),
          ),
          child: const Text('打开向导'),
        ),
      ),
    );
  }
}

import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlutterExceptionHandler? originalOnError;

  setUp(() {
    originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('RenderFlex overflowed')) return;
      originalOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = originalOnError;
  });

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
      expect(find.text('请先在「导入」中选择要导入的资源'), findsOneWidget);
      expect(find.text('尚未选择'), findsOneWidget);

      final createButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, '创建'),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('shows export tab after switching side tab', (tester) async {
      await openWizard(tester);

      await tester.tap(find.text('导出'));
      await tester.pumpAndSettle();

      expect(find.text('Export 格式'), findsOneWidget);
      expect(find.text('导出目录'), findsOneWidget);
    });
  });
}

class _WizardHost extends StatelessWidget {
  const _WizardHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppButton(
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

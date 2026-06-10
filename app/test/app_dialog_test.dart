import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('showAppFeatureDialog', () {
    testWidgets('uses expanded max width at wide viewport', (tester) async {
      _setViewport(tester, const Size(1300, 800));

      await tester.pumpWidget(
        const MaterialApp(home: _FeatureDialogHost()),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Dialog)).width, 800);
    });

    testWidgets('updates max width when window grows across breakpoints', (
      tester,
    ) async {
      _setViewport(tester, const Size(900, 800));

      await tester.pumpWidget(
        const MaterialApp(home: _FeatureDialogHost()),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Dialog)).width, 680);

      tester.view.physicalSize = const Size(1300, 800);
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Dialog)).width, 800);
    });
  });
}

class _FeatureDialogHost extends StatelessWidget {
  const _FeatureDialogHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppButton(
          onPressed: () => showAppFeatureDialog<void>(
            context: context,
            builder: (dialogContext) => const AppDialog(
              title: '测试',
              content: Text('内容'),
            ),
          ),
          child: const Text('打开'),
        ),
      ),
    );
  }
}

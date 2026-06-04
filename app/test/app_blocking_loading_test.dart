import 'package:comic_book_maker/ui/core/design_system/app_blocking_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runAppBlockingOperation shows then dismisses loading dialog', (
    WidgetTester tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    final value = await runAppBlockingOperation<int>(
                      context: context,
                      message: '正在创建项目…',
                      operation: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 20),
                        );
                        return 1;
                      },
                    );
                    completed = value == 1;
                  },
                  child: const Text('run'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pump();
    expect(find.text('正在创建项目…'), findsOneWidget);

    for (var i = 0; i < 20 && !completed; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(completed, isTrue);
    expect(find.text('正在创建项目…'), findsNothing);
  });
}

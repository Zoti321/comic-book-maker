import 'package:comic_book_maker/ui/core/design_system/app_toast.dart';
import 'package:comic_book_maker/ui/core/design_system/app_toast_controller.dart';
import 'package:comic_book_maker/ui/core/design_system/app_toast_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AppToastController.debugReset);
  tearDown(AppToastController.debugReset);

  testWidgets('showLoading then success updates toast in place', (
    WidgetTester tester,
  ) async {
    late AppToastHandle handle;

    await tester.pumpWidget(
      const MaterialApp(
        home: AppToastHost(
          child: SizedBox.shrink(),
        ),
      ),
    );

    handle = AppToastController.instance.showLoading(
      message: '正在创建「测试」…',
    );
    await tester.pump();

    expect(find.text('正在创建「测试」…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    handle.success('「测试」已创建');
    await tester.pump();

    expect(find.text('「测试」已创建'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('正在创建「测试」…'), findsNothing);

    AppToastController.debugReset();
  });

  testWidgets('dismissed loading toast still shows completion toast', (
    WidgetTester tester,
  ) async {
    late AppToastHandle handle;

    await tester.pumpWidget(
      const MaterialApp(
        home: AppToastHost(
          child: SizedBox.shrink(),
        ),
      ),
    );

    handle = AppToastController.instance.showLoading(message: '正在创建…');
    await tester.pump();
    expect(find.text('正在创建…'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.text('正在创建…'), findsNothing);

    handle.success('「测试」已创建');
    await tester.pump();
    expect(find.text('「测试」已创建'), findsOneWidget);

    AppToastController.debugReset();
  });

  testWidgets('multiple toasts stack vertically', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppToastHost(
          child: SizedBox.shrink(),
        ),
      ),
    );

    AppToastController.instance.showLoading(message: '任务 A');
    AppToastController.instance.showLoading(message: '任务 B');
    await tester.pump();

    expect(find.text('任务 A'), findsOneWidget);
    expect(find.text('任务 B'), findsOneWidget);
    expect(find.byType(AppToast), findsNWidgets(2));

    AppToastController.debugReset();
  });

  testWidgets('error toast shows action label', (WidgetTester tester) async {
    late AppToastHandle handle;
    var actionPressed = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: AppToastHost(
          child: SizedBox.shrink(),
        ),
      ),
    );

    handle = AppToastController.instance.showLoading(message: '正在创建…');
    await tester.pump();

    handle.error(
      '创建失败：示例错误',
      action: AppToastAction(
        label: '查看详情',
        onPressed: () => actionPressed = true,
      ),
    );
    await tester.pump();

    expect(find.text('创建失败：示例错误'), findsOneWidget);
    await tester.tap(find.text('查看详情'));
    expect(actionPressed, isTrue);

    AppToastController.debugReset();
  });
}

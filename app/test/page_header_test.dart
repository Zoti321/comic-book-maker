import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<double> pumpHeaderHeight(
    WidgetTester tester, {
    required Widget header,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: header),
      ),
    );
    return tester.getSize(find.byType(PageHeader)).height;
  }

  testWidgets('uses flat surface background without shadow', (tester) async {
    setWideViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: PageHeader(title: '设置'),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(PageHeader),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNull);
  });

  testWidgets('matches height with and without actions on wide layout', (
    tester,
  ) async {
    setWideViewport(tester);

    final titleOnlyHeight = await pumpHeaderHeight(
      tester,
      header: const PageHeader(title: '设置'),
    );

    final withActionsHeight = await pumpHeaderHeight(
      tester,
      header: PageHeader(
        title: '漫画库',
        actions: [
          AppButton(
            size: AppButtonSize.sm,
            onPressed: () {},
            child: const Text('新建项目'),
          ),
        ],
      ),
    );

    expect(titleOnlyHeight, withActionsHeight);
  });

  testWidgets('adds status bar inset to top padding', (tester) async {
    setWideViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: const Scaffold(
            body: PageHeader(title: '漫画库'),
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(PageHeader),
        matching: find.byType(Padding),
      ),
    );

    expect(
      (padding.padding as EdgeInsets).top,
      AppSpacing.md + 24,
    );
  });

  testWidgets('keeps default top padding when status bar inset is zero', (
    tester,
  ) async {
    setWideViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: PageHeader(title: '设置'),
        ),
      ),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(PageHeader),
        matching: find.byType(Padding),
      ),
    );

    expect((padding.padding as EdgeInsets).top, AppSpacing.md);
  });
}

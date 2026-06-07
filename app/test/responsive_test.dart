import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('breakpointOf', () {
    testWidgets('compact below 720', (tester) async {
      await tester.pumpWidget(_shell(width: 600));
      expect(breakpointOf(tester.element(find.byType(Scaffold))), AppBreakpoint.compact);
      expect(useAppSidebar(tester.element(find.byType(Scaffold))), isFalse);
    });

    testWidgets('medium between 720 and 1199', (tester) async {
      await tester.pumpWidget(_shell(width: 900));
      expect(breakpointOf(tester.element(find.byType(Scaffold))), AppBreakpoint.medium);
      expect(useAppSidebar(tester.element(find.byType(Scaffold))), isTrue);
    });

    testWidgets('expanded at 1200 and above', (tester) async {
      await tester.pumpWidget(_shell(width: 1400));
      expect(breakpointOf(tester.element(find.byType(Scaffold))), AppBreakpoint.expanded);
    });
  });

  group('contentWidthOf', () {
    testWidgets('subtracts sidebar width when sidebar is shown', (tester) async {
      await tester.pumpWidget(_shell(width: 1000));
      final context = tester.element(find.byType(Scaffold));
      expect(contentWidthOf(context), 1000 - AppLayout.sidebarWidth - 1);
    });

    testWidgets('uses full width on compact', (tester) async {
      await tester.pumpWidget(_shell(width: 400));
      final context = tester.element(find.byType(Scaffold));
      expect(contentWidthOf(context), 400);
    });
  });

  group('gridColumnsForWidth', () {
    test('maps width thresholds to column counts', () {
      expect(gridColumnsForWidth(200), 1);
      expect(gridColumnsForWidth(300), 2);
      expect(gridColumnsForWidth(500), 3);
      expect(gridColumnsForWidth(600), 4);
      expect(gridColumnsForWidth(800), 5);
      expect(gridColumnsForWidth(1000), 6);
      expect(gridColumnsForWidth(1300), 7);
    });

    test('respects min and max columns', () {
      expect(gridColumnsForWidth(2000, minColumns: 3, maxColumns: 5), 5);
      expect(gridColumnsForWidth(100, minColumns: 2), 2);
    });
  });
}

Widget _shell({required double width}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: const Scaffold(body: SizedBox.shrink()),
    ),
  );
}

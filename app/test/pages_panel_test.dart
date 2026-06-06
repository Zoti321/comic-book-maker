import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/project_editor/pages/pages_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pages = [
    PageSummary(
      id: 'page-1',
      sortIndex: 0,
      assetPath: 'assets/page-1.png',
      absolutePath: r'C:\temp\page-1.png',
    ),
    PageSummary(
      id: 'page-2',
      sortIndex: 1,
      assetPath: 'assets/page-2.png',
      absolutePath: r'C:\temp\page-2.png',
    ),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  group('PageThumbnailGrid', () {
    testWidgets('shows page count cover badge and add tile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PageThumbnailGrid(
            pages: pages,
            coverPageIndex: 0,
            onAdd: () {},
            onReplace: (_) {},
            onDelete: (_) {},
            onSetCover: (_) {},
            onViewOriginal: (_) {},
            onMoveEarlier: (_) {},
            onMoveLater: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 页'), findsOneWidget);
      expect(find.text('封面'), findsOneWidget);
      expect(find.text('添加页面'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('invokes onAdd from add tile', (tester) async {
      var addCount = 0;

      await tester.pumpWidget(
        wrap(
          PageThumbnailGrid(
            pages: pages,
            coverPageIndex: 0,
            onAdd: () => addCount++,
            onReplace: (_) {},
            onDelete: (_) {},
            onSetCover: (_) {},
            onViewOriginal: (_) {},
            onMoveEarlier: (_) {},
            onMoveLater: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('添加页面'));
      await tester.pump();

      expect(addCount, 1);
    });

  });
}

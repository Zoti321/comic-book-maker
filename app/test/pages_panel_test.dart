import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/cover_thumbnail_image.dart';
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

  group('coverThumbnailCacheSize for page grid tiles', () {
    test('8 columns at 900px width with dpr 1', () {
      final tile = pageThumbnailTileSize(900);
      expect(tile.width, 102);
      expect(tile.height, 136);

      final cache = coverThumbnailCacheSize(
        displayWidth: tile.width,
        displayHeight: tile.height,
        devicePixelRatio: 1,
      );
      expect(cache.width, 102);
      expect(cache.height, 136);
    });

    test('3 columns at 360px width with dpr 2', () {
      final tile = pageThumbnailTileSize(360);
      expect(tile.width, 112);
      expect(tile.height, closeTo(149.33, 0.01));

      final cache = coverThumbnailCacheSize(
        displayWidth: tile.width,
        displayHeight: tile.height,
        devicePixelRatio: 2,
      );
      expect(cache.width, 224);
      expect(cache.height, 299);
    });
  });

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
      expect(find.byType(MenuAnchor), findsNWidgets(2));
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

    testWidgets('passes cache dimensions to thumbnail images', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      final tile = pageThumbnailTileSize(900);
      final cache = coverThumbnailCacheSize(
        displayWidth: tile.width,
        displayHeight: tile.height,
        devicePixelRatio: 1,
      );

      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 900,
            child: PageThumbnailGrid(
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
        ),
      );
      await tester.pump();

      expect(find.byType(CoverThumbnailImage), findsNWidgets(pages.length));

      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images.length, pages.length);
      for (final image in images) {
        expect(image.filterQuality, FilterQuality.low);
        expect(image.gaplessPlayback, isTrue);
        final provider = image.image;
        expect(provider, isA<ResizeImage>());
        final resize = provider as ResizeImage;
        expect(resize.width, cache.width);
        expect(resize.height, cache.height);
      }
    });
  });
}

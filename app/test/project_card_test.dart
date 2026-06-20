import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/app_surface_ink_well.dart';
import 'package:comic_book_maker/ui/core/widgets/cover_thumbnail_image.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and uses Material Card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProjectCard(
            title: '测试漫画',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试漫画'), findsOneWidget);
    expect(find.text('最近打开'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.elevation, 1);

    expect(find.byType(AppSurfaceInkWell), findsOneWidget);

    final surfaceInk = tester.widget<AppSurfaceInkWell>(
      find.byType(AppSurfaceInkWell),
    );
    expect(surfaceInk.preset, AppSurfaceInkPreset.libraryCard);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProjectCard(
            title: '可点击',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('可点击'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('passes cache dimensions to cover thumbnail image', (tester) async {
    const cellWidth = 180.0;
    final cellHeight =
        cellWidth / ProjectCard.coverAspectRatio + ProjectCard.footerHeightEstimate;

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: ProjectCard(
              title: '有封面',
              coverThumbnailPath: r'C:\missing\cover.webp',
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CoverThumbnailImage), findsOneWidget);

    final cover = tester.widget<CoverThumbnailImage>(
      find.byType(CoverThumbnailImage),
    );
    expect(cover.cacheWidth, cellWidth.ceil());
    expect(cover.cacheHeight, greaterThan(200));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.filterQuality, FilterQuality.low);
    expect(image.gaplessPlayback, isTrue);

    final provider = image.image;
    expect(provider, isA<ResizeImage>());
    final resize = provider as ResizeImage;
    expect(resize.width, cover.cacheWidth);
    expect(resize.height, cover.cacheHeight);
  });
}

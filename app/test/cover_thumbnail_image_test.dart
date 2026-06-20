import 'package:comic_book_maker/ui/core/widgets/cover_thumbnail_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('coverThumbnailCacheSize', () {
    test('scales logical size by device pixel ratio', () {
      final cache = coverThumbnailCacheSize(
        displayWidth: 180,
        displayHeight: 240,
        devicePixelRatio: 1,
      );
      expect(cache.width, 180);
      expect(cache.height, 240);
    });

    test('ceil fractional physical pixels', () {
      final cache = coverThumbnailCacheSize(
        displayWidth: 112,
        displayHeight: 149.33,
        devicePixelRatio: 2,
      );
      expect(cache.width, 224);
      expect(cache.height, 299);
    });
  });
}

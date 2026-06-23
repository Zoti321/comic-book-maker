import 'package:comic_book_maker/domain/use_cases/app_release_notes_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseReleaseNoteBlocks', () {
    test('parses bullet lines and paragraphs', () {
      final blocks = parseReleaseNoteBlocks('''
- 新增高级搜索支持
- 图片预览现在支持多图浏览

其他说明
''');

      expect(blocks, hasLength(3));
      expect(blocks[0], isA<ReleaseNoteBullet>());
      expect((blocks[0] as ReleaseNoteBullet).text, '新增高级搜索支持');
      expect(blocks[1], isA<ReleaseNoteBullet>());
      expect((blocks[1] as ReleaseNoteBullet).text, '图片预览现在支持多图浏览');
      expect(blocks[2], isA<ReleaseNoteParagraph>());
      expect((blocks[2] as ReleaseNoteParagraph).text, '其他说明');
    });

    test('returns empty list for blank notes', () {
      expect(parseReleaseNoteBlocks(''), isEmpty);
      expect(parseReleaseNoteBlocks('   \n  '), isEmpty);
    });
  });

  group('parseReleasePublishedAt', () {
    test('parses GitHub ISO timestamp', () {
      final parsed = parseReleasePublishedAt('2026-06-18T08:30:00Z');

      expect(parsed, DateTime.utc(2026, 6, 18, 8, 30));
    });

    test('returns null for invalid values', () {
      expect(parseReleasePublishedAt(null), isNull);
      expect(parseReleasePublishedAt(''), isNull);
      expect(parseReleasePublishedAt('not-a-date'), isNull);
    });
  });

  group('formatReleasePublishedAtLabel', () {
    test('formats local calendar date', () {
      final label = formatReleasePublishedAtLabel(DateTime(2026, 6, 18));

      expect(label, '发布时间: 2026-06-18');
    });
  });
}

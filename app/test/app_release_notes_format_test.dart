import 'package:comic_book_maker/domain/use_cases/app_release_notes_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseReleaseNoteBlocks', () {
    test('extracts What\'s Changed bullets and strips PR links', () {
      final blocks = parseReleaseNoteBlocks('''
## What's Changed
* 修复 Android Release 导出无响应，并统一桌面 SnackBar 反馈 by @Zoti321 in https://github.com/Zoti321/comic-book-maker/pull/39
- 改进更新对话框 by @Zoti321 in https://github.com/Zoti321/comic-book-maker/pull/40

## 移动端
移动端说明不应显示

**Full Changelog**: https://github.com/Zoti321/comic-book-maker/compare/v1.1.0...v1.1.1
''');

      expect(blocks, hasLength(2));
      expect(blocks[0], isA<ReleaseNoteBullet>());
      expect(
        (blocks[0] as ReleaseNoteBullet).text,
        '修复 Android Release 导出无响应，并统一桌面 SnackBar 反馈 by @Zoti321',
      );
      expect(blocks[1], isA<ReleaseNoteBullet>());
      expect(
        (blocks[1] as ReleaseNoteBullet).text,
        '改进更新对话框 by @Zoti321',
      );
    });

    test('matches What\'s Changed header case-insensitively', () {
      final blocks = parseReleaseNoteBlocks('''
## what's changed
* 修复若干问题 by @Zoti321
''');

      expect(blocks, hasLength(1));
      expect((blocks.single as ReleaseNoteBullet).text, '修复若干问题 by @Zoti321');
    });

    test('returns empty list when What\'s Changed section is missing', () {
      expect(
        parseReleaseNoteBlocks('- 旧版手写说明\n其他说明'),
        isEmpty,
      );
      expect(
        parseReleaseNoteBlocks('What\'s Changed\n* 无二级标题'),
        isEmpty,
      );
    });

    test('returns empty list for blank notes', () {
      expect(parseReleaseNoteBlocks(''), isEmpty);
      expect(parseReleaseNoteBlocks('   \n  '), isEmpty);
    });

    test('returns empty list when What\'s Changed has no bullets', () {
      expect(
        parseReleaseNoteBlocks('''
## What's Changed
仅说明文字，无条目
'''),
        isEmpty,
      );
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

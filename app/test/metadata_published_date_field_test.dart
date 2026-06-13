import 'package:comic_book_maker/ui/features/project_editor/metadata_published_date_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetadataPublishedDateField.formatDisplayText', () {
    test('returns null when year is empty', () {
      expect(
        MetadataPublishedDateField.formatDisplayText(
          year: '',
          month: '',
          day: '',
        ),
        isNull,
      );
    });

    test('formats year-only partial', () {
      expect(
        MetadataPublishedDateField.formatDisplayText(
          year: '2024',
          month: '',
          day: '',
        ),
        '2024年',
      );
    });

    test('formats year-month partial', () {
      expect(
        MetadataPublishedDateField.formatDisplayText(
          year: '2024',
          month: '5',
          day: '',
        ),
        '2024年5月',
      );
    });

    test('formats full date', () {
      expect(
        MetadataPublishedDateField.formatDisplayText(
          year: '2024',
          month: '5',
          day: '31',
        ),
        '2024年5月31日',
      );
    });
  });

  group('MetadataPublishedDateField.initialPickerDate', () {
    test('uses Jan 1 for year-only partial', () {
      final date = MetadataPublishedDateField.initialPickerDate(
        year: '2024',
        month: '',
        day: '',
      );
      expect(date, DateTime(2024, 1, 1));
    });

    test('uses first day for year-month partial', () {
      final date = MetadataPublishedDateField.initialPickerDate(
        year: '2024',
        month: '5',
        day: '',
      );
      expect(date, DateTime(2024, 5, 1));
    });
  });
}

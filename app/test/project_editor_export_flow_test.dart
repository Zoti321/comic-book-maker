import 'package:comic_book_maker/ui/features/project_editor/project_editor_export_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readReadyGlobalExportDirectory', () {
    test('returns current value immediately when already loaded', () async {
      final result = await readReadyGlobalExportDirectory(
        const AsyncData(r'D:\exports'),
        awaitLoaded: () async => r'E:\fallback',
      );

      expect(result, r'D:\exports');
    });

    test('awaits provider future when current state is loading', () async {
      var awaited = false;
      final result = await readReadyGlobalExportDirectory(
        const AsyncLoading<String?>(),
        awaitLoaded: () async {
          awaited = true;
          return r'D:\exports';
        },
      );

      expect(awaited, isTrue);
      expect(result, r'D:\exports');
    });

    test('returns null when loading future throws', () async {
      final result = await readReadyGlobalExportDirectory(
        const AsyncLoading<String?>(),
        awaitLoaded: () async => throw Exception('prefs not ready'),
      );

      expect(result, isNull);
    });
  });
}

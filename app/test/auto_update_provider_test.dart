import 'package:comic_book_maker/providers/auto_update_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('autoUpdateFromStorage', () {
    test('defaults to true when missing', () {
      expect(autoUpdateFromStorage(null), isTrue);
    });

    test('restores stored value', () {
      expect(autoUpdateFromStorage(false), isFalse);
      expect(autoUpdateFromStorage(true), isTrue);
    });
  });

  group('auto_update persistence', () {
    test('writes and reads auto_update preference', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(autoUpdateFromStorage(prefs.getBool(autoUpdateStorageKey)), isTrue);

      await prefs.setBool(autoUpdateStorageKey, false);
      expect(autoUpdateFromStorage(prefs.getBool(autoUpdateStorageKey)), isFalse);

      await prefs.setBool(autoUpdateStorageKey, true);
      expect(autoUpdateFromStorage(prefs.getBool(autoUpdateStorageKey)), isTrue);
    });
  });
}

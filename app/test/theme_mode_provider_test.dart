import 'package:comic_book_maker/providers/theme_mode_provider.dart' hide ThemeMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('themeModeFromStorage', () {
    test('defaults to system when missing or unknown', () {
      expect(themeModeFromStorage(null), ThemeMode.system);
      expect(themeModeFromStorage(''), ThemeMode.system);
      expect(themeModeFromStorage('invalid'), ThemeMode.system);
    });

    test('restores light and dark', () {
      expect(themeModeFromStorage('light'), ThemeMode.light);
      expect(themeModeFromStorage('dark'), ThemeMode.dark);
      expect(themeModeFromStorage('system'), ThemeMode.system);
    });
  });

  group('themeModeToStorage', () {
    test('round-trips all modes', () {
      for (final mode in ThemeMode.values) {
        expect(themeModeFromStorage(themeModeToStorage(mode)), mode);
      }
    });
  });

  group('theme_mode persistence', () {
    test('writes and reads theme_mode preference', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(themeModeStorageKey, themeModeToStorage(ThemeMode.dark));
      expect(themeModeFromStorage(prefs.getString(themeModeStorageKey)),
          ThemeMode.dark);

      await prefs.setString(themeModeStorageKey, themeModeToStorage(ThemeMode.light));
      expect(themeModeFromStorage(prefs.getString(themeModeStorageKey)),
          ThemeMode.light);

      await prefs.remove(themeModeStorageKey);
      expect(themeModeFromStorage(prefs.getString(themeModeStorageKey)),
          ThemeMode.system);
    });
  });
}

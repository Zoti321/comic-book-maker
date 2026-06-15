import 'package:flutter/material.dart' as material;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

const themeModeStorageKey = 'theme_mode';

material.ThemeMode themeModeFromStorage(String? value) {
  return switch (value) {
    'light' => material.ThemeMode.light,
    'dark' => material.ThemeMode.dark,
    _ => material.ThemeMode.system,
  };
}

String themeModeToStorage(material.ThemeMode mode) {
  return switch (mode) {
    material.ThemeMode.light => 'light',
    material.ThemeMode.dark => 'dark',
    material.ThemeMode.system => 'system',
  };
}

@Riverpod(keepAlive: true)
class ThemeMode extends _$ThemeMode {
  @override
  Future<material.ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return themeModeFromStorage(prefs.getString(themeModeStorageKey));
  }

  Future<void> setMode(material.ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeStorageKey, themeModeToStorage(mode));
    state = AsyncData(mode);
  }
}

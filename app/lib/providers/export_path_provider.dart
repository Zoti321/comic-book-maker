import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'export_path_provider.g.dart';

const _storageKey = 'default_export_directory';

@Riverpod(keepAlive: true)
class ExportPath extends _$ExportPath {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> setDirectory(String directory) async {
    final trimmed = directory.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, trimmed);
    state = AsyncData(trimmed);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = const AsyncData(null);
  }
}

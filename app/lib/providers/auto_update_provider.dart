import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auto_update_provider.g.dart';

const autoUpdateStorageKey = 'auto_update_enabled';

bool autoUpdateFromStorage(bool? value) => value ?? true;

@Riverpod(keepAlive: true)
class AutoUpdate extends _$AutoUpdate {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return autoUpdateFromStorage(prefs.getBool(autoUpdateStorageKey));
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoUpdateStorageKey, enabled);
    state = AsyncData(enabled);
  }
}

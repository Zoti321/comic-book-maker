import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(resetAppUpdatePlatformOverride);

  test('treats desktop and android target platforms as supported', () {
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.android,
    ]) {
      appUpdatePlatformOverride = platform;
      expect(isAppUpdateSupportedPlatform(), isTrue);
    }
  });

  test('treats unsupported mobile target platforms as unsupported', () {
    for (final platform in [
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ]) {
      appUpdatePlatformOverride = platform;
      expect(isAppUpdateSupportedPlatform(), isFalse);
    }
  });
}

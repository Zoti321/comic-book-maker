import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(resetAppUpdatePlatformOverride);

  test('treats desktop target platforms as supported', () {
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      appUpdatePlatformOverride = platform;
      expect(isAppUpdateDesktopPlatform(), isTrue);
    }
  });

  test('treats mobile target platforms as unsupported', () {
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ]) {
      appUpdatePlatformOverride = platform;
      expect(isAppUpdateDesktopPlatform(), isFalse);
    }
  });
}

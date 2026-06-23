import 'package:comic_book_maker/domain/use_cases/mobile_export_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(resetMobileExportSaveFileOverride);

  test('uses override when configured', () {
    mobileExportSaveFileOverride = () => true;
    expect(usesMobileExportSaveFile(), isTrue);

    mobileExportSaveFileOverride = () => false;
    expect(usesMobileExportSaveFile(), isFalse);
  });

  test('defaults to false on test VM host', () {
    expect(usesMobileExportSaveFile(), isFalse);
  });
}

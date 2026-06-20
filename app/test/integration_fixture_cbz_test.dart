import '../tool/integration_fixture_cbz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodeIntegrationFixtureCbzBytes produces ZIP archive', () {
    final bytes = encodeIntegrationFixtureCbzBytes();
    expect(isZipArchiveBytes(bytes), isTrue);
    expect(bytes.length, greaterThan(100));
  });
}

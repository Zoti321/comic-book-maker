import 'package:comic_book_maker/domain/models/app_update_download_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computes determinate fraction and label', () {
    const progress = AppUpdateDownloadProgress(
      receivedBytes: 5 * 1024 * 1024,
      totalBytes: 10 * 1024 * 1024,
    );

    expect(progress.fraction, closeTo(0.5, 0.001));
    expect(progress.label, '已下载 5.0 MB / 10.0 MB');
  });

  test('returns null fraction when total is unknown', () {
    const progress = AppUpdateDownloadProgress(
      receivedBytes: 1024,
      totalBytes: null,
    );

    expect(progress.fraction, isNull);
    expect(progress.label, isNull);
  });
}

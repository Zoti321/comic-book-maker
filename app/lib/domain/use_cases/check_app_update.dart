import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';

sealed class AppUpdateCheckResult {
  const AppUpdateCheckResult();
}

final class AppUpdateUpToDate extends AppUpdateCheckResult {
  const AppUpdateUpToDate();
}

final class AppUpdateAvailable extends AppUpdateCheckResult {
  const AppUpdateAvailable(this.release);

  final AppUpdateRelease release;
}

class CheckAppUpdate {
  const CheckAppUpdate({required AppUpdateRepository repository})
      : _repository = repository;

  final AppUpdateRepository _repository;

  Future<AppUpdateCheckResult> call({required String currentVersion}) async {
    final release = await _repository.fetchLatestRelease();
    if (!isVersionNewer(release.version, currentVersion)) {
      return const AppUpdateUpToDate();
    }
    return AppUpdateAvailable(release);
  }
}

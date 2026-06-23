import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/use_cases/check_app_update.dart';
import 'package:comic_book_maker/domain/use_cases/download_app_update.dart';
import 'package:comic_book_maker/domain/use_cases/install_app_update.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_providers.g.dart';

@Riverpod(keepAlive: true)
Dio appUpdateDio(Ref ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.github.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'ComicBookMaker',
      },
    ),
  );
}

@Riverpod(keepAlive: true)
Dio appUpdateDownloadDio(Ref ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      headers: const {
        'User-Agent': 'ComicBookMaker',
      },
    ),
  );
}

@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) {
  return GitHubAppUpdateRepository(
    apiDio: ref.watch(appUpdateDioProvider),
    downloadDio: ref.watch(appUpdateDownloadDioProvider),
  );
}

@Riverpod(keepAlive: true)
CheckAppUpdate checkAppUpdate(Ref ref) {
  return CheckAppUpdate(repository: ref.watch(appUpdateRepositoryProvider));
}

@Riverpod(keepAlive: true)
DownloadAppUpdate downloadAppUpdate(Ref ref) {
  return DownloadAppUpdate(repository: ref.watch(appUpdateRepositoryProvider));
}

@Riverpod(keepAlive: true)
InstallAppUpdate installAppUpdate(Ref ref) {
  return InstallAppUpdate();
}

@Riverpod(keepAlive: true)
class AppUpdateSession extends _$AppUpdateSession {
  @override
  bool build() => false;

  /// 本次应用生命周期内不再自动弹出更新 dialog。
  void dismissForSession() {
    state = true;
  }

  @visibleForTesting
  void resetForTesting() {
    state = false;
  }
}

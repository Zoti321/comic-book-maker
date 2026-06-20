import 'package:comic_book_maker/bootstrap/comic_book_maker_bootstrap.dart';

export 'comic_book_maker_app.dart';

Future<void> main() async {
  const appDataOverride = String.fromEnvironment('CBM_APP_DATA_DIR');
  await bootstrapComicBookMaker(
    appDataDir: appDataOverride.isEmpty ? null : appDataOverride,
  );
}

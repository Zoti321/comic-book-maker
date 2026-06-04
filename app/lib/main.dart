import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final appDir = await getApplicationSupportDirectory();
  initLibrary(appDataDir: appDir.path);

  runApp(const ProviderScope(child: ComicBookMakerApp()));
}

class ComicBookMakerApp extends StatelessWidget {
  const ComicBookMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Comic Book Maker',
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

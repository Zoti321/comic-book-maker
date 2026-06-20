import 'package:comic_book_maker/ui/core/design_system/app_toast_host.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_shell.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/providers/theme_mode_provider.dart' hide ThemeMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ComicBookMakerApp extends ConsumerWidget {
  const ComicBookMakerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).maybeWhen(
          data: (mode) => mode,
          orElse: () => ThemeMode.system,
        );

    return MaterialApp.router(
      title: 'Comic Book Maker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
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
      builder: (context, child) {
        return AppToastHost(
          child: DesktopShell(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

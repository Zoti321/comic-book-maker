import 'package:comic_book_maker/router/app_routes.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/library_page.dart';
import 'package:comic_book_maker/ui/project_editor_page.dart';
import 'package:comic_book_maker/ui/settings_page.dart';
import 'package:comic_book_maker/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.projects,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.projects,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: LibraryPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.projectEditor,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final project = state.extra as ProjectSummary?;
        if (project == null) {
          return const Scaffold(
            body: Center(child: Text('缺少项目信息')),
          );
        }
        return ProjectEditorPage(project: project);
      },
    ),
  ],
);

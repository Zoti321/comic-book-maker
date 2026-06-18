import 'package:comic_book_maker/ui/core/router/app_page_transitions.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_feature.dart';
import 'package:comic_book_maker/ui/features/library/library_page.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_route_page.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_properties_feature.dart';
import 'package:comic_book_maker/ui/features/settings/settings_page.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
              routes: [
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => fadeTransitionPage(
                    key: state.pageKey,
                    child: const CreateProjectWizardFeature(),
                  ),
                ),
              ],
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
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final projectId = state.pathParameters['projectId'];
        if (projectId == null || projectId.isEmpty) {
          return fadeTransitionPage(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: Text('缺少项目信息')),
            ),
          );
        }
        return fadeTransitionPage(
          key: state.pageKey,
          child: ProjectEditorRoutePage(
            projectId: projectId,
            initialProject: state.extra as ProjectSummary?,
          ),
        );
      },
      routes: [
        GoRoute(
          path: 'properties',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) {
            final projectId = state.pathParameters['projectId'];
            if (projectId == null || projectId.isEmpty) {
              return fadeTransitionPage(
                key: state.pageKey,
                child: const Scaffold(
                  body: Center(child: Text('缺少项目信息')),
                ),
              );
            }
            return fadeTransitionPage(
              key: state.pageKey,
              child: ProjectPropertiesFeature(projectId: projectId),
            );
          },
        ),
      ],
    ),
  ],
);

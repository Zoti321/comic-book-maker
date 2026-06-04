import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_export_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'leaveProjectEditorAfterDeletedExport goes to library when PopScope blocks pop',
    (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.projects,
        routes: [
          GoRoute(
            path: AppRoutes.projects,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('library')),
            ),
          ),
          GoRoute(
            path: AppRoutes.projectEditor,
            builder: (context, state) => PopScope(
              canPop: false,
              child: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => Consumer(
                      builder: (context, ref, _) {
                        return FilledButton(
                          onPressed: () {
                            leaveProjectEditorAfterDeletedExport(
                              context: context,
                              ref: ref,
                              projectId: state.pathParameters['projectId']!,
                            );
                          },
                          child: const Text('leave'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.go(AppRoutes.projectEditorPath('p1'));
      await tester.pumpAndSettle();

      expect(find.text('editor'), findsNothing);
      expect(router.state.uri.path, AppRoutes.projectEditorPath('p1'));

      expect(router.routerDelegate.navigatorKey.currentState!.canPop(), isFalse);

      await tester.tap(find.text('leave'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.projects);
      expect(find.text('library'), findsOneWidget);
    },
  );
}

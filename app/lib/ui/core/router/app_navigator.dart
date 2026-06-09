import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 根 [Navigator]（[GoRouter] 与全站 Toast action 共用）。
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// 从任意异步回调打开项目编辑页（不依赖 feature [BuildContext]）。
void openProjectEditor(ProjectSummary project) {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  context.push(
    AppRoutes.projectEditorPath(project.id),
    extra: project,
  );
}

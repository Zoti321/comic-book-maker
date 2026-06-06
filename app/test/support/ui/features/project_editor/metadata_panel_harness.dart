import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_panel.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/repositories/in_memory_core_gateway.dart';
import '../../../provider/core_gateway_scope.dart';

/// 在固定高度下 pump [`MetadataPanel`]（`projectId` 默认为 `p1`）。
Future<void> pumpMetadataPanel(
  WidgetTester tester, {
  required ExportFormatFrb exportFormat,
  CoreGateway? gateway,
  String projectId = 'p1',
  int pageCount = 3,
}) async {
  final effectiveGateway = gateway ?? InMemoryCoreGateway.metadataPanel();
  await tester.pumpWidget(
    coreGatewayScope(
      gateway: effectiveGateway,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: MetadataPanel(
              projectId: projectId,
              pageCount: pageCount,
              exportFormat: exportFormat,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

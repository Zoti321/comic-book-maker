import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/metadata_panel.dart';
import 'package:comic_book_maker/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 在固定高度下 pump [`MetadataPanel`]（`projectId` 默认为 `p1`）。
Future<void> pumpMetadataPanel(
  WidgetTester tester, {
  required ExportFormatFrb exportFormat,
  String projectId = 'p1',
  int pageCount = 3,
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
  );
  await tester.pumpAndSettle();
}

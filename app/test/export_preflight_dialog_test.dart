import 'dart:io';

import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('shows overwrite dialog and cancels export when user declines', (
    WidgetTester tester,
  ) async {
    final tempRoot = Directory.systemTemp.createTempSync('cbm-export-ui-');
    addTearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    final exportDir = Directory(p.join(tempRoot.path, 'exports'))..createSync();
    final destination = File(p.join(exportDir.path, 'comic.cbz'))
      ..writeAsStringSync('existing');
    var exportStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  final preflight = checkExportPreflight(destination.path);
                  final confirmed = await runExportConfirmations(
                    preflight: preflight,
                    deleteAfterExport: false,
                    confirmOverwrite: () async {
                      if (!context.mounted) return false;
                      final result = await showAppConfirmDialog(
                        context: context,
                        title: '覆盖已有文件？',
                        description: Text(
                          '目标位置已存在文件：\n${destination.path}\n\n'
                          '继续将覆盖该文件。',
                        ),
                        confirmLabel: '覆盖并导出',
                        destructive: true,
                      );
                      return result == true;
                    },
                    confirmDeleteProject: () async => true,
                  );
                  if (confirmed) {
                    exportStarted = true;
                  }
                },
                child: const Text('export'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('export'));
    await tester.pumpAndSettle();

    expect(find.text('覆盖已有文件？'), findsOneWidget);
    expect(find.text('覆盖并导出'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(exportStarted, isFalse);
  });
}

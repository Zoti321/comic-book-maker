import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_release_notes_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows empty-state message and published date', (tester) async {
    final release = AppUpdateRelease(
      version: '2.0.0',
      tagName: 'v2.0.0',
      releaseNotes: '',
      releasePageUrl: 'https://example.com/release',
      downloadUrl: 'https://example.com/win.exe',
      publishedAt: DateTime.utc(2026, 6, 18),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppUpdateReleaseNotesContent(release: release),
        ),
      ),
    );

    expect(find.text('暂无更新说明'), findsOneWidget);
    expect(find.text('发布时间: 2026-06-18'), findsOneWidget);
  });

  testWidgets('renders bullet notes and published date', (tester) async {
    final release = AppUpdateRelease(
      version: '2.0.0',
      tagName: 'v2.0.0',
      releaseNotes: '- 修复导出问题\n- 改进更新对话框',
      releasePageUrl: 'https://example.com/release',
      downloadUrl: 'https://example.com/win.exe',
      publishedAt: DateTime.utc(2026, 6, 18),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppUpdateReleaseNotesContent(release: release),
        ),
      ),
    );

    expect(find.text('- 修复导出问题'), findsOneWidget);
    expect(find.text('- 改进更新对话框'), findsOneWidget);
    expect(find.text('发布时间: 2026-06-18'), findsOneWidget);
  });
}

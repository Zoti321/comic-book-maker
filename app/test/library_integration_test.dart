import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frb/rust_integration.dart';

void main() {
  rustIntegrationTestSetUpAll();

  group('Library FRB integration', () {
    rustIntegrationTestSetUp(onReady: (_) {});

    test('createProject and listProjects round-trip', () {
      expect(listProjects(), isEmpty);

      final created = createProject(title: '集成测试');
      final listed = listProjects();

      expect(listed, hasLength(1));
      expect(listed.single.id, created.id);
      expect(listed.single.title, '集成测试');
    });

    test('updateProjectTitle persists in catalog', () {
      final created = createProject(title: '旧标题');
      final updated = updateProjectTitle(
        projectId: created.id,
        title: '新标题',
      );

      expect(updated.title, '新标题');
      expect(listProjects().single.title, '新标题');
    });

    test('deleteProject removes catalog entry', () {
      final created = createProject(title: '待删');
      deleteProject(projectId: created.id);
      expect(listProjects(), isEmpty);
    });

    test('touchProject updates lastOpenedAtMs', () {
      final created = createProject(title: '打开记录');
      expect(created.lastOpenedAtMs, isNull);

      touchProject(projectId: created.id);
      final touched = listProjects().single;

      expect(touched.lastOpenedAtMs, isNotNull);
    });
  });
}

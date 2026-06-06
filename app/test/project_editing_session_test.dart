import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/project_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

void main() {
  late InMemoryCoreGateway gateway;
  late ProjectEditingSession session;

  setUp(() {
    gateway = InMemoryCoreGateway.editorProject();
    session = ProjectEditingSession(gateway: gateway);
  });

  group('ProjectEditingSession.loadEditor', () {
    test('returns pages settings and cover index from snapshot', () {
      final load = session.loadEditor('p1');

      expect(load.pages, hasLength(1));
      expect(load.settings.exportFormat, ExportFormatFrb.comicArchive);
      expect(load.coverPageIndex, 0);
    });
  });

  group('ProjectEditingSession.metadataWorkspacePatch', () {
    test('maps title and cover page index from metadata', () {
      const metadata = Metadata(
        title: '新标题',
        coverPageIndex: 2,
        pageCount: 3,
      );

      final patch = session.metadataWorkspacePatch(metadata);

      expect(patch.projectTitle, '新标题');
      expect(patch.coverPageIndex, 2);
    });
  });

  group('ProjectEditingSession.pageIdsAfterSwap', () {
    test('swaps with previous page when moving earlier', () {
      final pages = [
        PageSummary(
          id: 'a',
          sortIndex: 0,
          assetPath: 'a.png',
          absolutePath: r'C:\a.png',
        ),
        PageSummary(
          id: 'b',
          sortIndex: 1,
          assetPath: 'b.png',
          absolutePath: r'C:\b.png',
        ),
      ];

      final ids = session.pageIdsAfterSwap(pages, 'b', moveEarlier: true);

      expect(ids, ['b', 'a']);
    });

    test('no-op when already first page', () {
      final pages = [
        PageSummary(
          id: 'a',
          sortIndex: 0,
          assetPath: 'a.png',
          absolutePath: r'C:\a.png',
        ),
      ];

      final ids = session.pageIdsAfterSwap(pages, 'a', moveEarlier: true);

      expect(ids, ['a']);
    });
  });

  group('ProjectEditingSession.setCoverPage', () {
    test('persists cover index through gateway', () async {
      final coverPageIndex = session.setCoverPage(
        projectId: 'p1',
        sortIndex: 0,
        pageCount: 1,
      );

      expect(coverPageIndex, 0);
      expect(
        gateway.metadataFor('p1').coverPageIndex,
        0,
      );
    });
  });
}

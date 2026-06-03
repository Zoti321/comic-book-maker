import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/metadata_panel_harness.dart';
import 'support/rust_fake.dart';

void main() {
  setUpAll(() => initRustTestFake(FakeRustLibApi.metadataPanel()));

  testWidgets('comic archive export format shows ComicInfo fields', (tester) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.comicArchive);

    expect(find.text('导入元数据（只读）'), findsOneWidget);
    expect(
      find.textContaining('导入资源中没有元数据'),
      findsOneWidget,
    );
    expect(find.text('导出元数据'), findsOneWidget);
    expect(find.text('ComicInfo'), findsWidgets);
    expect(find.text('卷号'), findsOneWidget);
    expect(find.text('编辑模型'), findsNothing);
  });

  testWidgets('epub export format shows OPF and fixed-layout sections', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.epub);

    expect(find.text('OPF Metadata'), findsWidgets);
    expect(find.text('标识符 (GTIN/ISBN)'), findsOneWidget);
    expect(find.text('rendition:layout'), findsNothing);

    await tester.tap(find.text('固定版式'));
    await tester.pumpAndSettle();

    expect(find.text('rendition:layout'), findsOneWidget);
    expect(find.text('pre-paginated'), findsOneWidget);
  });

  testWidgets('pdf export format shows placeholder without editable form', (
    tester,
  ) async {
    await pumpMetadataPanel(tester, exportFormat: ExportFormatFrb.pdf);

    expect(find.textContaining('PDF Export 尚未实现'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
    expect(find.text('标题'), findsNothing);
  });
}

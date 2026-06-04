import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/metadata_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

Map<String, String> _textFieldValues(MetadataEditingSession session) {
  final values = <String, String>{};
  for (final field in session.schema.sections.expand((s) => s.fields)) {
    if (MetadataEditingSession.fieldUsesTextController(field.kind)) {
      values[field.id] = session.displayValueForField(field.id);
    }
  }
  return values;
}

void main() {
  late InMemoryCoreGateway gateway;

  setUp(() {
    gateway = InMemoryCoreGateway.metadataPanel();
    gateway.metadataByProjectId['p1'] = kMetadataPanelFixture;
    gateway.metadataUpdateCallCount = 0;
    gateway.nextMetadataUpdateError = null;
    gateway.failMetadataUpdates = false;
    gateway.onMetadataUpdate = null;
  });

  test('load exposes metadata with page count', () async {
    final session = MetadataEditingSession(
      projectId: 'p1',
      exportFormat: ExportFormatFrb.comicArchive,
      pageCount: 5,
      gateway: gateway,
    );
    addTearDown(session.dispose);

    await session.load();

    expect(session.loading, isFalse);
    expect(session.metadata?.pageCount, 5);
    expect(session.metadata?.title, kMetadataPanelFixture.title);
  });

  test('debounced save persists when validation passes', () async {
    final session = MetadataEditingSession(
      projectId: 'p1',
      exportFormat: ExportFormatFrb.comicArchive,
      pageCount: 3,
      gateway: gateway,
    );
    addTearDown(session.dispose);
    await session.load();

    final values = _textFieldValues(session);
    values['volume'] = '42';
    session.scheduleDebouncedSave(
      validateForm: () => true,
      readTextFieldValues: () => values,
    );

    await Future<void>.delayed(metadataAutosaveDebounce + const Duration(milliseconds: 50));

    expect(gateway.metadataUpdateCallCount, 1);
    expect(gateway.metadataByProjectId['p1']?.volume, '42');
    expect(session.dirty, isFalse);
  });

  test('flushForNavigation saves pending edits', () async {
    final session = MetadataEditingSession(
      projectId: 'p1',
      exportFormat: ExportFormatFrb.comicArchive,
      pageCount: 3,
      gateway: gateway,
    );
    addTearDown(session.dispose);
    await session.load();

    final values = _textFieldValues(session);
    values['volume'] = '8';
    session.markDirty();
    final ok = await session.flushForNavigation(
      validateForm: () => true,
      readTextFieldValues: () => values,
    );

    expect(ok, isTrue);
    expect(gateway.metadataUpdateCallCount, 1);
    expect(gateway.metadataByProjectId['p1']?.volume, '8');
  });

  test('concurrent text edits reschedule save after server write', () async {
    final session = MetadataEditingSession(
      projectId: 'p1',
      exportFormat: ExportFormatFrb.comicArchive,
      pageCount: 3,
      gateway: gateway,
    );
    addTearDown(session.dispose);
    await session.load();

    final values = _textFieldValues(session);
    values['volume'] = '12';

    gateway.onMetadataUpdate = () {
      values['volume'] = '123';
    };

    session.markDirty();
    await session.save(
      validateForm: () => true,
      readTextFieldValues: () => values,
    );

    expect(gateway.metadataByProjectId['p1']?.volume, '12');
    expect(session.takeSkipSyncFieldIds(), contains('volume'));
    expect(session.dirty, isTrue);

    values['volume'] = '123';
    session.markDirty();
    await session.save(
      validateForm: () => true,
      readTextFieldValues: () => values,
    );

    expect(gateway.metadataByProjectId['p1']?.volume, '123');
    expect(session.dirty, isFalse);
  });
}

import 'dart:async';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';

import 'package:flutter/foundation.dart';



const metadataAutosaveDebounce = Duration(milliseconds: 600);

const metadataSaveIdlePoll = Duration(milliseconds: 16);



/// 保存结果写回表单时，哪些文本字段因并发编辑不应被覆盖。

class MetadataFieldSyncResult {

  const MetadataFieldSyncResult({

    required this.metadata,

    required this.skipSyncFieldIds,

    required this.rescheduleSave,

  });



  final Metadata metadata;

  final Set<String> skipSyncFieldIds;

  final bool rescheduleSave;

}



/// Project 元数据编辑会话：加载、防抖保存、flush、与 Core 同步。

class MetadataEditingSession extends ChangeNotifier {

  MetadataEditingSession({

    required this.projectId,

    required this.exportFormat,

    required int pageCount,

    MetadataSessionGateway? gateway,

    this.onSaved,

  })  : _pageCount = pageCount,

        _gateway = gateway ?? const FrbCoreGateway() {

    _schema = _gateway.getMetadataEditorSchema(exportFormat: exportFormat);

  }



  final String projectId;

  final ExportFormatFrb exportFormat;

  final void Function(Metadata)? onSaved;

  final MetadataSessionGateway _gateway;



  late final MetadataEditorSchemaFrb _schema;

  int _pageCount;



  Metadata? _metadata;

  bool _loading = true;

  bool _saving = false;

  bool _dirty = false;

  String? _loadError;

  String? _saveError;



  Timer? _debounceTimer;

  Set<String> _skipSyncFieldIds = const {};

  int _formSyncGeneration = 0;



  MetadataEditorSchemaFrb get schema => _schema;

  int get formSyncGeneration => _formSyncGeneration;

  Metadata? get metadata => _metadata;

  bool get loading => _loading;

  bool get saving => _saving;

  bool get dirty => _dirty;

  String? get loadError => _loadError;

  String? get saveError => _saveError;

  int get pageCount => _pageCount;



  /// 消费最近一次写回后不应覆盖的文本字段 id（供 UI 同步 controller）。

  Set<String> takeSkipSyncFieldIds() {

    final ids = _skipSyncFieldIds;

    _skipSyncFieldIds = const {};

    return ids;

  }



  static bool fieldUsesTextController(MetadataFieldKindFrb kind) {

    return switch (kind) {

      MetadataFieldKindFrb.text ||

      MetadataFieldKindFrb.multilineText ||

      MetadataFieldKindFrb.integer ||

      MetadataFieldKindFrb.ageRating ||

      MetadataFieldKindFrb.publishedDate ||

      MetadataFieldKindFrb.commaSeparatedTags =>

        true,

    };

  }



  static bool fieldUsesTextField(MetadataFieldSpecFrb field) =>

      fieldUsesTextController(field.kind);



  static Iterable<String> formFieldIdsFor(MetadataFieldSpecFrb field) sync* {

    if (field.formFieldIds.isNotEmpty) {

      yield* field.formFieldIds;

    } else if (fieldUsesTextController(field.kind)) {

      yield field.id;

    }

  }



  static Iterable<String> textFieldIdsFor(MetadataFieldSpecFrb field) =>

      formFieldIdsFor(field);



  Iterable<MetadataFieldSpecFrb> get _editableFields sync* {

    for (final section in _schema.sections) {

      for (final field in section.fields) {

        if (fieldUsesTextField(field)) yield field;

      }

    }

  }



  String displayValueForField(String fieldId) {

    final current = _metadata;

    if (current == null) return '';

    return _gateway.metadataFieldDisplayValue(

      metadata: current,

      fieldId: fieldId,

    );

  }



  Future<void> load() async {

    _loading = true;

    _loadError = null;

    _saveError = null;

    notifyListeners();



    try {

      final context = _gateway.loadMetadataEditingContext(projectId: projectId);

      _metadata = _withPageCount(context.metadata);

      _loading = false;

      _dirty = false;

      _bumpFormSyncGeneration();

      notifyListeners();

    } catch (e) {

      _loading = false;

      _loadError = e.toString();

      notifyListeners();

    }

  }



  void setPageCount(int pageCount) {

    if (_pageCount == pageCount) return;

    _pageCount = pageCount;

    final current = _metadata;

    if (current != null) {

      _metadata = _withPageCount(current);

      notifyListeners();

    }

  }



  void _bumpFormSyncGeneration() {

    _formSyncGeneration++;

  }



  MetadataFieldSyncResult applyServerMetadata(

    Metadata value, {

    Map<String, String>? submittedTextFieldValues,

    required Map<String, String> currentTextFieldValues,

  }) {

    final withPageCount = _withPageCount(value);

    _metadata = withPageCount;



    final skipSync = <String>{};

    if (submittedTextFieldValues != null) {

      for (final field in _editableFields) {

        for (final fieldId in textFieldIdsFor(field)) {

          final submitted = submittedTextFieldValues[fieldId];

          if (submitted != null &&

              currentTextFieldValues[fieldId] != submitted) {

            skipSync.add(fieldId);

          }

        }

      }

    }



    final reschedule = skipSync.isNotEmpty;

    if (reschedule) {

      _dirty = true;

    }

    _skipSyncFieldIds = skipSync;

    _bumpFormSyncGeneration();



    notifyListeners();

    return MetadataFieldSyncResult(

      metadata: withPageCount,

      skipSyncFieldIds: skipSync,

      rescheduleSave: reschedule,

    );

  }



  void patchDropdownField({required String fieldId, String? value}) {

    final current = _metadata;

    if (current == null) return;

    _metadata = _gateway.metadataWithDropdownField(

      metadata: current,

      fieldId: fieldId,

      value: value,

    );

    _dirty = true;

    notifyListeners();

  }



  void markDirty() {

    if (_dirty) return;

    _dirty = true;

    notifyListeners();

  }



  void clearSaveError() {

    if (_saveError == null) return;

    _saveError = null;

    notifyListeners();

  }



  void scheduleDebouncedSave({

    required bool Function() validateForm,

    required Map<String, String> Function() readTextFieldValues,

  }) {

    markDirty();

    _cancelDebounce();

    _debounceTimer = Timer(metadataAutosaveDebounce, () {

      unawaited(

        save(

          validateForm: validateForm,

          readTextFieldValues: readTextFieldValues,

        ),

      );

    });

  }



  Future<bool> save({

    required bool Function() validateForm,

    required Map<String, String> Function() readTextFieldValues,

  }) async {

    _cancelDebounce();

    await _waitForSaveIdle();

    if (_metadata == null) return true;

    if (!_hasPendingSave() && _saveError == null) return true;

    if (!validateForm()) return false;



    _saving = true;

    _saveError = null;

    notifyListeners();



    final valuesAtStart = readTextFieldValues();

    final submitted = _captureTextFieldValues(valuesAtStart);



    try {

      final saved = _gateway.updateProjectMetadata(

        projectId: projectId,

        metadata: _buildMetadataFromForm(valuesAtStart),

      );

      final valuesAfterSave = readTextFieldValues();

      final sync = applyServerMetadata(

        saved,

        submittedTextFieldValues: submitted,

        currentTextFieldValues: valuesAfterSave,

      );

      if (sync.rescheduleSave) {

        scheduleDebouncedSave(

          validateForm: validateForm,

          readTextFieldValues: readTextFieldValues,

        );

      } else {

        _dirty = false;

        notifyListeners();

      }

      onSaved?.call(saved);

      return true;

    } catch (e) {

      _saveError = e.toString();

      notifyListeners();

      return false;

    } finally {

      _saving = false;

      notifyListeners();

    }

  }



  Future<bool> flushForNavigation({

    required bool Function() validateForm,

    required Map<String, String> Function() readTextFieldValues,

  }) async {

    await _waitForSaveIdle();

    if (_hasPendingSave()) {

      final saved = await save(

        validateForm: validateForm,

        readTextFieldValues: readTextFieldValues,

      );

      if (!saved) return false;

      await _waitForSaveIdle();

    }

    return _saveError == null;

  }



  @override

  void dispose() {

    _cancelDebounce();

    super.dispose();

  }



  Metadata _withPageCount(Metadata metadata) =>

      _gateway.metadataWithPageCount(

        metadata: metadata,

        pageCount: _pageCount,

      );



  Map<String, String> _captureTextFieldValues(

    Map<String, String> textFieldValues,

  ) {

    return Map<String, String>.from(textFieldValues);

  }



  List<MetadataFieldValueFrb> _collectFormValues(

    Map<String, String> textFieldValues,

  ) {

    final values = <MetadataFieldValueFrb>[];



    for (final section in _schema.sections) {

      for (final field in section.fields) {

        switch (field.kind) {

          case MetadataFieldKindFrb.text:

          case MetadataFieldKindFrb.multilineText:

          case MetadataFieldKindFrb.integer:

          case MetadataFieldKindFrb.ageRating:

          case MetadataFieldKindFrb.commaSeparatedTags:

            values.add(

              MetadataFieldValueFrb(

                fieldId: field.id,

                value: textFieldValues[field.id] ?? '',

              ),

            );

          case MetadataFieldKindFrb.publishedDate:

            for (final fieldId in formFieldIdsFor(field)) {

              values.add(

                MetadataFieldValueFrb(

                  fieldId: fieldId,

                  value: textFieldValues[fieldId] ?? '',

                ),

              );

            }

        }

      }

    }



    return values;

  }



  Metadata _buildMetadataFromForm(Map<String, String> textFieldValues) {

    return _gateway.mergeMetadataFromForm(

      exportFormat: exportFormat,

      base: _metadata!,

      fieldValues: _collectFormValues(textFieldValues),

      pageCount: _pageCount,

    );

  }



  void _cancelDebounce() {

    _debounceTimer?.cancel();

    _debounceTimer = null;

  }



  bool _hasPendingSave() => _debounceTimer != null || _dirty;



  Future<void> _waitForSaveIdle() async {

    while (_saving) {

      await Future<void>.delayed(metadataSaveIdlePoll);

    }

  }

}



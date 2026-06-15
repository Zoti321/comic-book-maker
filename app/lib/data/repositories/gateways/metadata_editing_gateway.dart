import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';

/// Metadata 表单与纯变换（无 projectId）。
abstract class MetadataEditingGateway {
  MetadataEditorSchemaFrb getMetadataEditorSchema({
    required ExportFormatFrb exportFormat,
  });

  Metadata metadataWithPageCount({
    required Metadata metadata,
    required int pageCount,
  });

  Metadata metadataWithDropdownField({
    required Metadata metadata,
    required String fieldId,
    String? value,
  });

  Metadata metadataWithCoverPageIndex({
    required Metadata metadata,
    required int coverPageIndex,
  });

  String metadataFieldDisplayValue({
    required Metadata metadata,
    required String fieldId,
  });

  Metadata mergeMetadataFromForm({
    required ExportFormatFrb exportFormat,
    required Metadata base,
    required List<MetadataFieldValueFrb> fieldValues,
    required int pageCount,
  });
}

import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/layout/responsive.dart';
import 'package:comic_book_maker/ui/import_metadata_preview.dart';
import 'package:comic_book_maker/ui/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/theme/app_theme.dart';
import 'package:comic_book_maker/ui/widgets/metadata_unsaved_banner.dart';
import 'package:comic_book_maker/ui/widgets/section_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MetadataPanel extends HookConsumerWidget {
  const MetadataPanel({
    super.key,
    required this.projectId,
    required this.pageCount,
    required this.exportFormat,
    this.onSaved,
    this.onDirtyChanged,
    this.discardGeneration = 0,
    this.scrollController,
  });

  final String projectId;
  final int pageCount;
  final ExportFormatFrb exportFormat;
  final ValueChanged<Metadata>? onSaved;
  final ValueChanged<bool>? onDirtyChanged;
  final int discardGeneration;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schema = useMemoized(
      () => getMetadataEditorSchema(exportFormat: exportFormat),
      [exportFormat],
    );
    final metadata = useState<Metadata?>(null);
    final loadError = useState<String?>(null);
    final saveError = useState<String?>(null);
    final loading = useState(true);
    final saving = useState(false);
    final dirty = useState(false);
    final sectionIndex = useState(0);
    final importSnapshot = useState<ImportMetadataSnapshotFrb?>(null);
    final inferredImportKind = useState<InferredImportKindFrb?>(null);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final controllers = useRef(<String, TextEditingController>{});

    void syncController(String key, String value) {
      final field = controllers.value.putIfAbsent(
        key,
        TextEditingController.new,
      );
      if (field.text != value) field.text = value;
    }

    bool usesTextController(MetadataFieldKindFrb kind) {
      return switch (kind) {
        MetadataFieldKindFrb.text ||
        MetadataFieldKindFrb.multilineText ||
        MetadataFieldKindFrb.integer ||
        MetadataFieldKindFrb.ageRating =>
          true,
        _ => false,
      };
    }

    void applyMetadata(Metadata value) {
      final withPageCount = metadataWithPageCount(
        metadata: value,
        pageCount: pageCount,
      );
      metadata.value = withPageCount;
      for (final section in schema.sections) {
        for (final field in section.fields) {
          if (usesTextController(field.kind)) {
            syncController(
              field.id,
              metadataFieldDisplayValue(
                metadata: withPageCount,
                fieldId: field.id,
              ),
            );
          }
        }
      }
    }

    TextEditingController fieldController(String key) =>
        controllers.value.putIfAbsent(key, TextEditingController.new);

    void setDirty(bool value) {
      if (dirty.value == value) return;
      dirty.value = value;
      onDirtyChanged?.call(value);
    }

    void markDirty() => setDirty(true);

    Future<void> loadMetadata() async {
      loading.value = true;
      loadError.value = null;
      saveError.value = null;

      try {
        final loaded = getProjectMetadata(projectId: projectId);
        applyMetadata(loaded);
        importSnapshot.value =
            getImportMetadataSnapshot(projectId: projectId);
        inferredImportKind.value =
            getProjectSettings(projectId: projectId).inferredImportKind;
        loading.value = false;
        setDirty(false);
      } catch (e) {
        loading.value = false;
        loadError.value = e.toString();
      }
    }

    useEffect(() {
      loadMetadata();
      return null;
    }, [projectId]);

    useEffect(() {
      if (discardGeneration == 0) return null;
      loadMetadata();
      return null;
    }, [discardGeneration]);

    useEffect(() {
      sectionIndex.value = 0;
      return null;
    }, [exportFormat]);

    useEffect(() {
      final current = metadata.value;
      if (current != null && current.pageCount != pageCount) {
        applyMetadata(current);
      }
      try {
        importSnapshot.value =
            getImportMetadataSnapshot(projectId: projectId);
      } catch (_) {}
      return null;
    }, [pageCount]);

    useEffect(() {
      return () {
        for (final c in controllers.value.values) {
          c.dispose();
        }
        controllers.value.clear();
      };
    }, const []);

    List<MetadataFieldValueFrb> collectFormValues() {
      final current = metadata.value!;
      final values = <MetadataFieldValueFrb>[];

      for (final section in schema.sections) {
        for (final field in section.fields) {
          switch (field.kind) {
            case MetadataFieldKindFrb.text:
            case MetadataFieldKindFrb.multilineText:
            case MetadataFieldKindFrb.integer:
            case MetadataFieldKindFrb.ageRating:
              values.add(
                MetadataFieldValueFrb(
                  fieldId: field.id,
                  value: fieldController(field.id).text,
                ),
              );
            case MetadataFieldKindFrb.dropdown:
              values.add(
                MetadataFieldValueFrb(
                  fieldId: field.id,
                  value: metadataFieldDisplayValue(
                    metadata: current,
                    fieldId: field.id,
                  ),
                ),
              );
            case MetadataFieldKindFrb.readOnly:
            case MetadataFieldKindFrb.coverPageIndex:
            case MetadataFieldKindFrb.pageCountInfo:
              break;
          }
        }
      }

      return values;
    }

    Metadata buildMetadataFromForm() {
      return mergeMetadataFromForm(
        exportFormat: exportFormat,
        base: metadata.value!,
        fieldValues: collectFormValues(),
        pageCount: pageCount,
      );
    }

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;

      saving.value = true;
      saveError.value = null;

      try {
        final saved = updateProjectMetadata(
          projectId: projectId,
          metadata: buildMetadataFromForm(),
        );
        applyMetadata(saved);
        saving.value = false;
        setDirty(false);
        onSaved?.call(saved);
        if (context.mounted) {
          showAppOperationSuccessSnackBar(context, '元数据已保存');
        }
      } catch (e) {
        saving.value = false;
        saveError.value = e.toString();
      }
    }

    Widget readOnlyField(String label, String value) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Widget textField(
      MetadataFieldSpecFrb field, {
      int maxLines = 1,
    }) {
      return TextFormField(
        controller: fieldController(field.id),
        decoration: InputDecoration(
          labelText: field.label,
          alignLabelWithHint: maxLines > 1,
        ),
        maxLines: maxLines,
        validator: field.required_
            ? (v) => (v == null || v.trim().isEmpty) ? '必填' : null
            : null,
        onChanged: (_) => markDirty(),
      );
    }

    Widget intField(MetadataFieldSpecFrb field) {
      final min = field.intMin ?? 0;
      final max = field.intMax ?? 9999;
      return TextFormField(
        controller: fieldController(field.id),
        decoration: InputDecoration(labelText: field.label),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return null;
          final parsed = int.tryParse(text);
          if (parsed == null) return '请输入整数';
          if (parsed < min || parsed > max) return '范围 $min–$max';
          return null;
        },
        onChanged: (_) => markDirty(),
      );
    }

    Widget dropdownField(MetadataFieldSpecFrb field) {
      final current = metadata.value!;
      final value = metadataFieldDisplayValue(
        metadata: current,
        fieldId: field.id,
      );
      final selected = value.isEmpty ? null : value;

      return DropdownButtonFormField<String>(
        key: ValueKey('${field.id}-$selected'),
        initialValue:
            selected != null && field.options.contains(selected) ? selected : null,
        decoration: InputDecoration(labelText: field.label),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('未设置')),
          ...field.options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
        ],
        onChanged: (next) {
          metadata.value = metadataWithDropdownField(
            metadata: current,
            fieldId: field.id,
            value: next,
          );
          markDirty();
        },
      );
    }

    Widget ageRatingField(MetadataFieldSpecFrb field) {
      final controller = fieldController(field.id);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: field.label,
                  hintText: '可选择预设或手动输入',
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空',
                          onPressed: () {
                            controller.clear();
                            markDirty();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (_) => markDirty(),
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in schema.ageRatingPresets)
                ActionChip(
                  label: Text(preset),
                  onPressed: () {
                    controller.text = preset;
                    markDirty();
                  },
                ),
            ],
          ),
        ],
      );
    }

    Widget fieldWidget(MetadataFieldSpecFrb field) {
      return switch (field.kind) {
        MetadataFieldKindFrb.text => textField(field),
        MetadataFieldKindFrb.multilineText => textField(field, maxLines: 5),
        MetadataFieldKindFrb.integer => intField(field),
        MetadataFieldKindFrb.dropdown => dropdownField(field),
        MetadataFieldKindFrb.ageRating => ageRatingField(field),
        MetadataFieldKindFrb.readOnly => readOnlyField(
          field.label,
          field.readOnlyValue ?? '',
        ),
        MetadataFieldKindFrb.pageCountInfo ||
        MetadataFieldKindFrb.coverPageIndex =>
          const SizedBox.shrink(),
      };
    }

    List<Widget> sectionFields() {
      if (sectionIndex.value >= schema.sections.length) {
        return [];
      }
      return schema.sections[sectionIndex.value].fields
          .map(fieldWidget)
          .toList();
    }

    if (loading.value) {
      return const AppPageLoading(message: '正在加载元数据…');
    }

    if (metadata.value == null) {
      return AppPageErrorState(
        title: '无法加载元数据',
        message: loadError.value,
        action: AppButton(onPressed: loadMetadata, child: const Text('重试')),
      );
    }

    final padding = AppSpacing.pagePadding(context);
    final sectionLabels =
        schema.sections.map((section) => section.label).toList();

    Widget headerRow(BoxConstraints headerConstraints) {
      final compactHeader = headerConstraints.maxWidth < 300;
      return Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        schema.editorTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (schema.editable && dirty.value) ...[
                      const SizedBox(width: 8),
                      _DirtyLabel(color: Theme.of(context).colorScheme.primary),
                    ],
                  ],
                ),
                Text(
                  'Export：${exportFormatLabel(exportFormat)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!schema.editable)
            const SizedBox.shrink()
          else if (compactHeader)
            AppIconButton(
              variant: AppIconButtonVariant.tonal,
              onPressed: saving.value || !dirty.value ? null : save,
              icon: saving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            )
          else
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: saving.value || !dirty.value ? null : save,
              icon: saving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              child: Text(saving.value ? '保存中' : '保存'),
            ),
        ],
      );
    }

    if (!schema.editable) {
      return Padding(
        padding: padding,
        child: AppEmptyState(
          icon: Icons.description_outlined,
          title: '当前格式不支持编辑',
          subtitle: schema.pdfMessage ??
              '请在「项目属性」中将 Export 格式改为 CBZ 或 EPUB 后再编辑元数据。',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;

        return CustomScrollView(
          controller: scrollController,
          shrinkWrap: !boundedHeight,
          physics: boundedHeight
              ? null
              : const NeverScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 0),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) => headerRow(constraints),
                ),
              ),
            ),
            if (importSnapshot.value != null)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 12, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: ImportMetadataPreview(
                    snapshot: importSnapshot.value!,
                    inferredImportKind: inferredImportKind.value,
                    exportFormatLabel: exportFormatLabel(exportFormat),
                  ),
                ),
              ),
            if (schema.editable && dirty.value)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 12, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: MetadataUnsavedBanner(
                    saving: saving.value,
                    onSave: save,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '导出元数据',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 0),
              sliver: SliverToBoxAdapter(
                child: SectionChipBar(
                  sections: sectionLabels,
                  selectedIndex: sectionIndex.value,
                  onSelected: (i) => sectionIndex.value = i,
                ),
              ),
            ),
            if (sectionIndex.value < schema.sections.length)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    schema.sections[sectionIndex.value].label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (saveError.value != null)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: AppInlineErrorBanner(
                    message: '保存失败：${saveError.value}',
                    onDismiss: () => saveError.value = null,
                  ),
                ),
              ),
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: formKey,
                  onChanged: markDirty,
                  child: ResponsiveFormGrid(children: sectionFields()),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _DirtyLabel extends StatelessWidget {
  const _DirtyLabel({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '未保存',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

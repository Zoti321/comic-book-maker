import 'dart:async';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/metadata_editing_session.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/import_metadata_preview.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/section_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 供项目编辑页在切 Tab / 返回前 flush 元数据自动保存。
class MetadataPanelController {
  Future<bool> Function()? _prepareForNavigation;
  bool Function()? _isSaving;

  Future<bool> prepareForNavigation() async =>
      await (_prepareForNavigation?.call() ?? Future.value(true));

  bool get isSaving => _isSaving?.call() ?? false;

  void attach({
    required Future<bool> Function() prepareForNavigation,
    required bool Function() isSaving,
  }) {
    _prepareForNavigation = prepareForNavigation;
    _isSaving = isSaving;
  }

  void detach() {
    _prepareForNavigation = null;
    _isSaving = null;
  }
}

class MetadataPanel extends HookConsumerWidget {
  const MetadataPanel({
    super.key,
    required this.projectId,
    required this.pageCount,
    required this.exportFormat,
    this.controller,
    this.onSaved,
    this.scrollController,
    this.gateway,
  });

  final String projectId;
  final int pageCount;
  final ExportFormatFrb exportFormat;
  final MetadataPanelController? controller;
  final ValueChanged<Metadata>? onSaved;
  final ScrollController? scrollController;
  final CoreGateway? gateway;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionIndex = useState(0);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final controllers = useRef(<String, TextEditingController>{});

    final session = useMemoized(
      () => MetadataEditingSession(
        projectId: projectId,
        exportFormat: exportFormat,
        pageCount: pageCount,
        gateway: gateway ?? const FrbCoreGateway(),
        onSaved: onSaved,
      ),
      [projectId, exportFormat, gateway],
    );

    useListenable(session);

    useEffect(() {
      unawaited(session.load());
      return session.dispose;
    }, [session]);

    useEffect(() {
      sectionIndex.value = 0;
      return null;
    }, [exportFormat]);

    useEffect(() {
      session.setPageCount(pageCount);
      return null;
    }, [pageCount, session]);

    useEffect(() {
      return () {
        for (final c in controllers.value.values) {
          c.dispose();
        }
        controllers.value.clear();
      };
    }, const []);

    TextEditingController fieldController(String key) =>
        controllers.value.putIfAbsent(key, TextEditingController.new);

    void syncController(String key, String value) {
      final field = fieldController(key);
      if (field.text != value) field.text = value;
    }

    Map<String, String> captureTextFieldValues() {
      final values = <String, String>{};
      for (final field in session.schema.sections.expand((s) => s.fields)) {
        if (MetadataEditingSession.fieldUsesTextController(field.kind)) {
          values[field.id] = fieldController(field.id).text;
        }
      }
      return values;
    }

    bool validateForm() => formKey.currentState?.validate() ?? false;

    void syncControllersFromSession({Set<String> skipFieldIds = const {}}) {
      for (final field in session.schema.sections.expand((s) => s.fields)) {
        if (!MetadataEditingSession.fieldUsesTextController(field.kind)) {
          continue;
        }
        if (skipFieldIds.contains(field.id)) continue;
        syncController(
          field.id,
          session.displayValueForField(field.id),
        );
      }
    }

    useEffect(() {
      if (session.loading || session.metadata == null) return null;
      syncControllersFromSession(
        skipFieldIds: session.takeSkipSyncFieldIds(),
      );
      return null;
    }, [session.loading, session.formSyncGeneration]);

    Future<bool> saveNow() => session.save(
          validateForm: validateForm,
          readTextFieldValues: captureTextFieldValues,
        );

    Future<bool> prepareForNavigation() => session.flushForNavigation(
          validateForm: validateForm,
          readTextFieldValues: captureTextFieldValues,
        );

    useEffect(() {
      final panelController = controller;
      if (panelController == null) return null;

      panelController.attach(
        prepareForNavigation: prepareForNavigation,
        isSaving: () => session.saving,
      );
      return panelController.detach;
    }, [controller, session]);

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

    void onTextFieldChanged() {
      session.scheduleDebouncedSave(
        validateForm: validateForm,
        readTextFieldValues: captureTextFieldValues,
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
        onChanged: (_) => onTextFieldChanged(),
        onEditingComplete: () => unawaited(saveNow()),
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
        onChanged: (_) => onTextFieldChanged(),
        onEditingComplete: () => unawaited(saveNow()),
      );
    }

    Widget dropdownField(MetadataFieldSpecFrb field) {
      final value = session.displayValueForField(field.id);
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
          session.patchDropdownField(fieldId: field.id, value: next);
          unawaited(saveNow());
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
                            onTextFieldChanged();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (_) => onTextFieldChanged(),
                onEditingComplete: () => unawaited(saveNow()),
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in session.schema.ageRatingPresets)
                ActionChip(
                  label: Text(preset),
                  onPressed: () {
                    controller.text = preset;
                    onTextFieldChanged();
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
      if (sectionIndex.value >= session.schema.sections.length) {
        return [];
      }
      return session.schema.sections[sectionIndex.value].fields
          .map(fieldWidget)
          .toList();
    }

    if (session.loading) {
      return const AppPageLoading(message: '正在加载元数据…');
    }

    if (session.metadata == null) {
      return AppPageErrorState(
        title: '无法加载元数据',
        message: session.loadError,
        action: AppButton(
          onPressed: () => unawaited(session.load()),
          child: const Text('重试'),
        ),
      );
    }

    final padding = AppSpacing.pagePadding(context);
    final sectionLabels =
        session.schema.sections.map((section) => section.label).toList();

    Widget headerRow() {
      final theme = Theme.of(context);

      return Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.schema.editorTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Export：${exportFormatLabel(exportFormat)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (session.schema.editable && session.saving) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '保存中…',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    if (!session.schema.editable) {
      return Padding(
        padding: padding,
        child: AppEmptyState(
          icon: Icons.description_outlined,
          title: '当前格式不支持编辑',
          subtitle: session.schema.pdfMessage ??
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
              sliver: SliverToBoxAdapter(child: headerRow()),
            ),
            if (session.importSnapshot != null)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 12, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: ImportMetadataPreview(
                    snapshot: session.importSnapshot!,
                    inferredImportKind: session.inferredImportKind,
                    exportFormatLabel: exportFormatLabel(exportFormat),
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
            if (sectionIndex.value < session.schema.sections.length)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    session.schema.sections[sectionIndex.value].label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (session.saveError != null)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: AppInlineErrorBanner(
                    message: '保存失败：${session.saveError}',
                    onRetry: () => unawaited(saveNow()),
                    onDismiss: session.clearSaveError,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: formKey,
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

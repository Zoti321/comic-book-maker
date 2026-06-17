import 'dart:async';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/metadata_editing_session.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_age_rating_field.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_published_date_field.dart';
import 'package:comic_book_maker/ui/features/project_editor/metadata_comma_tags_field.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_inline_error_banner.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_page_states.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/section_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final MetadataSessionGateway? gateway;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionIndex = useState(0);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final controllers = useRef(<String, TextEditingController>{});
    final focusNodes = useRef(<String, FocusNode>{});

    final effectiveGateway = gateway ?? ref.read(coreGatewayProvider);
    final session = useMemoized(
      () => MetadataEditingSession(
        projectId: projectId,
        exportFormat: exportFormat,
        pageCount: pageCount,
        gateway: effectiveGateway,
        onSaved: onSaved,
      ),
      [projectId, exportFormat, effectiveGateway],
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
        for (final node in focusNodes.value.values) {
          node.dispose();
        }
        focusNodes.value.clear();
      };
    }, const []);

    TextEditingController fieldController(String key) =>
        controllers.value.putIfAbsent(key, TextEditingController.new);

    FocusNode focusNodeFor(String key) =>
        focusNodes.value.putIfAbsent(key, FocusNode.new);

    void syncController(String key, String value) {
      if (focusNodeFor(key).hasFocus) return;
      final field = fieldController(key);
      if (field.value.text == value) return;
      field.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    Map<String, String> captureTextFieldValues() {
      final values = <String, String>{};
      for (final field in session.schema.sections.expand((s) => s.fields)) {
        for (final fieldId in MetadataEditingSession.textFieldIdsFor(field)) {
          values[fieldId] = fieldController(fieldId).text;
        }
      }
      return values;
    }

    bool validateForm() => formKey.currentState?.validate() ?? false;

    void syncControllersFromSession({Set<String> skipFieldIds = const {}}) {
      for (final field in session.schema.sections.expand((s) => s.fields)) {
        for (final fieldId in MetadataEditingSession.textFieldIdsFor(field)) {
          if (skipFieldIds.contains(fieldId)) continue;
          syncController(fieldId, session.displayValueForField(fieldId));
        }
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

    void onTextFieldChanged() {
      session.scheduleDebouncedSave(
        validateForm: validateForm,
        readTextFieldValues: captureTextFieldValues,
      );
    }

    Widget commaTagsField(MetadataFieldSpecFrb field) {
      return MetadataCommaTagsField(
        controller: fieldController(field.id),
        focusNode: focusNodeFor(field.id),
        label: field.label,
        onChanged: onTextFieldChanged,
        onEditingComplete: () => unawaited(saveNow()),
      );
    }

    Widget publishedDateField(MetadataFieldSpecFrb field) {
      final formIds = MetadataEditingSession.formFieldIdsFor(field).toList();
      assert(
        formIds.length == 3,
        'publishedDate field must expose year/month/day form ids',
      );
      return MetadataPublishedDateField(
        label: field.label,
        yearController: fieldController(formIds[0]),
        monthController: fieldController(formIds[1]),
        dayController: fieldController(formIds[2]),
        onChanged: onTextFieldChanged,
        onEditingComplete: () => unawaited(saveNow()),
      );
    }

    Widget textField(
      MetadataFieldSpecFrb field, {
      int maxLines = 1,
    }) {
      return TextFormField(
        controller: fieldController(field.id),
        focusNode: focusNodeFor(field.id),
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
        focusNode: focusNodeFor(field.id),
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

    Widget ageRatingField(MetadataFieldSpecFrb field) {
      return MetadataAgeRatingField(
        label: field.label,
        controller: fieldController(field.id),
        presets: session.schema.ageRatingPresets,
        onChanged: onTextFieldChanged,
      );
    }

    Widget fieldWidget(MetadataFieldSpecFrb field) {
      return switch (field.kind) {
        MetadataFieldKindFrb.commaSeparatedTags => commaTagsField(field),
        MetadataFieldKindFrb.text => textField(field),
        MetadataFieldKindFrb.multilineText => textField(field, maxLines: 5),
        MetadataFieldKindFrb.integer => intField(field),
        MetadataFieldKindFrb.ageRating => ageRatingField(field),
        MetadataFieldKindFrb.publishedDate => publishedDateField(field),
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
      return const ProjectEditorPageLoading(message: '正在加载元数据…');
    }

    if (session.metadata == null) {
      return ProjectEditorPageErrorState(
        title: '无法加载元数据',
        message: session.loadError,
        action: FilledButton(
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
            child: Text(
              session.schema.editorTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (session.schema.editable && session.saving) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceVariant,
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
        child: ProjectEditorEmptyState(
          icon: LucideIcons.fileText,
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
            if (session.saveError != null)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0),
                sliver: SliverToBoxAdapter(
                  child: ProjectEditorInlineErrorBanner(
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

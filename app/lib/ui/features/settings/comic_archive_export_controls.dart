import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:comic_book_maker/ui/core/widgets/app_dropdown_menu.dart';
import 'package:comic_book_maker/ui/features/settings/export_settings_layout.dart';
import 'package:flutter/material.dart';

/// 漫画压缩包扩展名勾选文案。
const kComicArchiveExtensionCheckboxLabel = '使用漫画扩展名（cbz/cbr/cb7 等）';

/// 漫画压缩包 Export 的容器算法与扩展名策略控件。
class ComicArchiveExportControls extends StatelessWidget {
  const ComicArchiveExportControls({
    super.key,
    required this.settings,
    required this.enabled,
    required this.onContainerChanged,
    required this.onUseComicExtensionChanged,
    this.layout = ExportSettingsLayout.stacked,
  });

  final ProjectSettings settings;
  final bool enabled;
  final ValueChanged<ComicArchiveContainerFrb> onContainerChanged;
  final ValueChanged<bool> onUseComicExtensionChanged;
  final ExportSettingsLayout layout;

  static const _containers = ComicArchiveContainerFrb.values;

  bool get _horizontal => layout == ExportSettingsLayout.horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final implemented = isComicArchiveContainerImplemented(
      container: settings.comicArchiveContainer,
    );

    final containerSelect = AppDropdownMenu<ComicArchiveContainerFrb>(
      key: ValueKey(settings.comicArchiveContainer),
      label: _horizontal ? null : '压缩算法',
      value: settings.comicArchiveContainer,
      enabled: enabled,
      items: [
        for (final container in _containers)
          AppDropdownMenuItem(
            value: container,
            label: comicArchiveContainerMenuLabel(container),
            enabled: isComicArchiveContainerSelectable(container: container),
          ),
      ],
      onChanged: enabled
          ? (value) {
              if (value == null) return;
              if (!isComicArchiveContainerSelectable(container: value)) {
                return;
              }
              onContainerChanged(value);
            }
          : null,
    );

    final extensionCheckbox = Row(
      children: [
        Checkbox(
          value: settings.useComicArchiveExtension,
          onChanged: enabled
              ? (value) => onUseComicExtensionChanged(value ?? false)
              : null,
        ),
        Expanded(
          child: Text(
            kComicArchiveExtensionCheckboxLabel,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_horizontal)
          _LabeledFieldRow(
            label: '压缩算法',
            child: containerSelect,
          )
        else
          containerSelect,
        if (!implemented) ...[
          const SizedBox(height: 8),
          Text(
            '当前算法尚未实现 Export，请改用 ZIP 或等待后续版本。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_horizontal)
          _LabeledFieldRow(
            reserveLeadingSpace: true,
            child: extensionCheckbox,
          )
        else
          extensionCheckbox,
      ],
    );
  }
}

class _LabeledFieldRow extends StatelessWidget {
  const _LabeledFieldRow({
    required this.child,
    this.label,
    this.reserveLeadingSpace = false,
  });

  final Widget child;
  final String? label;
  final bool reserveLeadingSpace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const labelWidth = 160.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: label == null
              ? const SizedBox.shrink()
              : Text(
                  label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}

String comicArchiveContainerMenuLabel(ComicArchiveContainerFrb container) {
  final name = comicArchiveContainerLabel(container: container);
  if (isComicArchiveContainerSelectable(container: container)) {
    return name;
  }
  return '$name（尚未实现）';
}

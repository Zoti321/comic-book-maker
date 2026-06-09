import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
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
    this.exampleBaseName = '我的漫画',
    this.layout = ExportSettingsLayout.stacked,
    this.minimalCopy = false,
  });

  final ProjectSettings settings;
  final bool enabled;
  final ValueChanged<ComicArchiveContainerFrb> onContainerChanged;
  final ValueChanged<bool> onUseComicExtensionChanged;
  final String exampleBaseName;
  final ExportSettingsLayout layout;
  final bool minimalCopy;

  static const _containers = ComicArchiveContainerFrb.values;

  bool get _horizontal => layout == ExportSettingsLayout.horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final extension = comicArchiveFileExtension(settings);
    final implemented = isComicArchiveContainerImplemented(settings);

    final containerSelect = AppSelect<ComicArchiveContainerFrb>(
      key: ValueKey(settings.comicArchiveContainer),
      label: _horizontal ? null : '压缩算法',
      enabled: enabled,
      value: settings.comicArchiveContainer,
      onChanged: enabled ? onContainerChanged : null,
      items: [
        for (final container in _containers)
          AppSelectItem(
            value: container,
            label: comicArchiveContainerMenuLabel(container),
            displayLabel: comicArchiveContainerLabel(container),
            enabled: comicArchiveContainerSelectable(container),
          ),
      ],
    );

    final extensionCheckbox = AppCheckbox(
      value: settings.useComicArchiveExtension,
      onChanged: enabled
          ? (value) => onUseComicExtensionChanged(value ?? false)
          : null,
      label: kComicArchiveExtensionCheckboxLabel,
      sublabel: minimalCopy
          ? null
          : '不勾选时使用通用压缩扩展名（.zip / .rar / .7z）',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_horizontal)
          AppLabeledFieldRow(
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
          AppLabeledFieldRow(
            reserveLeadingSpace: true,
            child: extensionCheckbox,
          )
        else
          extensionCheckbox,
        if (!minimalCopy) ...[
          const SizedBox(height: 8),
          Text(
            '导出文件名示例：$exampleBaseName.$extension',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

String comicArchiveContainerMenuLabel(ComicArchiveContainerFrb container) {
  final name = comicArchiveContainerLabel(container);
  if (comicArchiveContainerSelectable(container)) {
    return switch (container) {
      ComicArchiveContainerFrb.zip => '$name（可用，对应 CBZ Export）',
      ComicArchiveContainerFrb.rar => '$name（可用，对应 CBR Export）',
      ComicArchiveContainerFrb.sevenZip => '$name（可用）',
    };
  }
  return '$name（尚未实现）';
}

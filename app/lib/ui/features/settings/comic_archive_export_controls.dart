import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:flutter/material.dart';

/// 漫画压缩包 Export 的容器算法（二级菜单）与扩展名策略控件。
class ComicArchiveExportControls extends StatelessWidget {
  const ComicArchiveExportControls({
    super.key,
    required this.settings,
    required this.enabled,
    required this.onContainerChanged,
    required this.onUseComicExtensionChanged,
    this.exampleBaseName = '我的漫画',
  });

  final ProjectSettings settings;
  final bool enabled;
  final ValueChanged<ComicArchiveContainerFrb> onContainerChanged;
  final ValueChanged<bool> onUseComicExtensionChanged;
  final String exampleBaseName;

  static const _containers = ComicArchiveContainerFrb.values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final extension = comicArchiveFileExtension(settings);
    final implemented = isComicArchiveContainerImplemented(settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '漫画压缩包',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        _ContainerMenuAnchor(
          selected: settings.comicArchiveContainer,
          enabled: enabled,
          onSelected: onContainerChanged,
        ),
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
        AppCheckbox(
          value: settings.useComicArchiveExtension,
          onChanged: enabled
              ? (value) => onUseComicExtensionChanged(value ?? false)
              : null,
          label: '使用漫画扩展名',
          sublabel: '不勾选时使用通用压缩扩展名（.zip / .rar / .7z）',
        ),
        const SizedBox(height: 8),
        Text(
          '导出文件名示例：$exampleBaseName.$extension',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ContainerMenuAnchor extends StatelessWidget {
  const _ContainerMenuAnchor({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ComicArchiveContainerFrb selected;
  final bool enabled;
  final ValueChanged<ComicArchiveContainerFrb> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = comicArchiveContainerLabel(selected);
    final canExport = comicArchiveContainerSelectable(selected);

    return MenuAnchor(
      builder: (context, controller, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            variant: AppButtonVariant.outline,
            onPressed: enabled
                ? () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  }
                : null,
            icon: const Icon(Icons.expand_more),
            child: Text('压缩算法：$label${canExport ? '' : '（尚未实现）'}'),
          ),
        );
      },
      menuChildren: [
        for (final container in ComicArchiveExportControls._containers)
          MenuItemButton(
            onPressed: !enabled || !comicArchiveContainerSelectable(container)
                ? null
                : () => onSelected(container),
            leadingIcon: selected == container
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                : const SizedBox(width: 20),
            child: Text(_menuItemLabel(container)),
          ),
      ],
    );
  }

  String _menuItemLabel(ComicArchiveContainerFrb container) {
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
}

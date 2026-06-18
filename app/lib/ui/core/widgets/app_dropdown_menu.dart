import 'package:flutter/material.dart';

/// [AppDropdownMenu] 下拉项。
class AppDropdownMenuItem<T> {
  const AppDropdownMenuItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

/// Material 3 [DropdownMenu] 封装，与全局 Outlined 输入框视觉一致。
class AppDropdownMenu<T> extends StatelessWidget {
  const AppDropdownMenu({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.enableSearch = false,
    this.clearable = false,
    this.width,
    this.hintText,
    this.trailingIcon,
  });

  final String? label;
  final T? value;
  final List<AppDropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool enableSearch;
  final bool clearable;
  final double? width;
  final String? hintText;
  final Widget? trailingIcon;

  static Widget _ellipsisLabel(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildTrailingIcon({
    required bool canClear,
    required Widget? trailingIcon,
  }) {
    if (trailingIcon != null) {
      return trailingIcon;
    }
    if (!canClear) {
      return null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '清空',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          onPressed: () => onChanged?.call(null),
          icon: const Icon(Icons.close),
        ),
        const Icon(Icons.arrow_drop_down),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onChanged != null;
    final canClear =
        clearable && value != null && effectiveEnabled && trailingIcon == null;
    final useExpandedWidth = width == null;

    return DropdownMenu<T>(
      key: ValueKey<T?>(value),
      width: width,
      expandedInsets: useExpandedWidth ? EdgeInsets.zero : null,
      label: label != null ? Text(label!) : null,
      hintText: hintText,
      initialSelection: value,
      enabled: effectiveEnabled,
      enableSearch: enableSearch,
      trailingIcon: _buildTrailingIcon(
        canClear: canClear,
        trailingIcon: trailingIcon,
      ),
      onSelected: effectiveEnabled ? onChanged : null,
      dropdownMenuEntries: [
        for (final item in items)
          DropdownMenuEntry<T>(
            value: item.value,
            label: item.label,
            labelWidget: _ellipsisLabel(item.label),
            enabled: item.enabled,
          ),
      ],
    );
  }
}

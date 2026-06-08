import 'package:comic_book_maker/ui/core/design_system/app_popup_menu.dart';
import 'package:comic_book_maker/ui/core/design_system/app_popup_menu_panel.dart';
import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_fonts.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// [AppSelect] 下拉项。
class AppSelectItem<T> {
  const AppSelectItem({
    required this.value,
    required this.label,
    this.displayLabel,
    this.enabled = true,
  });

  final T value;
  final String label;

  /// 触发器展示文案；未设时与 [label] 相同。
  final String? displayLabel;
  final bool enabled;
}

/// 自绘下拉选择（shadcn Select 风格）；基于 [AppPopupMenu]。
class AppSelect<T> extends StatefulWidget {
  const AppSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.helper,
    this.enabled = true,
  });

  final T value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? helper;
  final bool enabled;

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  final _controller = AppPopupMenuController();
  final _triggerKey = GlobalKey();
  var _hovered = false;
  var _focused = false;
  double? _triggerWidth;

  bool get _interactive =>
      widget.enabled && widget.onChanged != null && widget.items.isNotEmpty;

  void _syncTriggerWidth() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final width = box.size.width;
    if (_triggerWidth != width) {
      setState(() => _triggerWidth = width);
    }
  }

  AppSelectItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedLabel =
        _selectedItem?.displayLabel ?? _selectedItem?.label ?? '';
    final showOpen = _controller.menuIsShowing;

    final field = Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        onEnter: _interactive ? (_) => setState(() => _hovered = true) : null,
        onExit: _interactive ? (_) => setState(() => _hovered = false) : null,
        cursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          key: _triggerKey,
          behavior: HitTestBehavior.opaque,
          onTap: _interactive
              ? () {
                  _syncTriggerWidth();
                  _controller.toggleMenu();
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: AppTypography.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: _focused
                    ? AppColors.primary
                    : _hovered || showOpen
                        ? AppColors.outlineVariant
                        : AppColors.outline,
                width: _focused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.textStyle(
                      scheme: scheme,
                      fontSize: AppTypography.bodySize,
                      color: widget.enabled
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: widget.enabled
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
        ],
        AppPopupMenu(
          controller: _controller,
          menuBuilder: () {
            _syncTriggerWidth();
            return AppPopupMenuPanel(
              width: _triggerWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs / 2,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in widget.items)
                    AppPopupMenuItem(
                      label: item.label,
                      enabled: item.enabled,
                      selected: item.value == widget.value,
                      leading: item.value == widget.value
                          ? Icon(
                              LucideIcons.check,
                              size: 18,
                              color: AppColors.onSurface,
                            )
                          : null,
                      onTap: () {
                        widget.onChanged?.call(item.value);
                        _controller.hideMenu();
                      },
                    ),
                ],
              ),
            );
          },
          child: field,
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

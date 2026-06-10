import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_fonts.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 自绘单行文本输入（与 [AppSelect] 对齐的 shadcn 风格）。
///
/// 内部使用无边框 [TextField]；描边、label、helper 由本组件绘制。
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownedFocusNode;
  var _focused = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  /// 仅键盘导航时展示 focus 描边，避免鼠标点击后误显粗边框。
  bool get _showKeyboardFocus =>
      _focused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_onFocusChanged);
    FocusManager.instance.addListener(_onFocusHighlightChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _ownedFocusNode?.removeListener(_onFocusChanged);
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
      if (widget.focusNode == null) {
        _ownedFocusNode = FocusNode();
      }
      _focusNode.addListener(_onFocusChanged);
      _focused = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusHighlightChanged);
    _focusNode.removeListener(_onFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (_focused != focused) {
      setState(() => _focused = focused);
    }
  }

  void _onFocusHighlightChanged() {
    if (mounted) setState(() {});
  }

  Color _borderColor() {
    if (_hasError) return AppColors.error;
    if (_showKeyboardFocus) return AppColors.primary;
    return AppColors.outline;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final textColor = widget.enabled
        ? AppColors.onSurface
        : AppColors.onSurfaceVariant;

    final field = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: AppTypography.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: _borderColor(), width: 1),
        ),
        alignment: Alignment.centerLeft,
        child: Theme(
          data: theme.copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLines: 1,
            style: AppFonts.textStyle(
              scheme: scheme,
              fontSize: AppTypography.bodySize,
              color: textColor,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: AppFonts.textStyle(
                scheme: scheme,
                fontSize: AppTypography.bodySize,
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
            onChanged: widget.onChanged,
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
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
        ],
        field,
        if (_hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

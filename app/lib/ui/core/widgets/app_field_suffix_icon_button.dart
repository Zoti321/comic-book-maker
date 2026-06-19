import 'package:flutter/material.dart';

/// 表单字段 suffix 用小圆形 [IconButton]（36×36，图标 20px）。
class AppFieldSuffixIconButton extends StatelessWidget {
  const AppFieldSuffixIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  static const buttonSize = 36.0;
  static const iconSize = 20.0;
  static const gap = 4.0;

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  static ButtonStyle buttonStyle() {
    return IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      fixedSize: const Size(buttonSize, buttonSize),
      minimumSize: const Size(buttonSize, buttonSize),
      maximumSize: const Size(buttonSize, buttonSize),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const CircleBorder(),
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: buttonStyle(),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

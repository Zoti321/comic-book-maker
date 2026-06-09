import 'package:flutter/material.dart';

/// 带主/副标题的复选框行（无 M3 水波纹；整行可点）。
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.sublabel,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final String? sublabel;

  bool get _interactive => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor:
          _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _interactive ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: AbsorbPointer(
                  child: Theme(
                    data: theme.copyWith(
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      checkboxTheme: theme.checkboxTheme.copyWith(
                        overlayColor:
                            const WidgetStatePropertyAll(Colors.transparent),
                      ),
                    ),
                    child: Checkbox(
                      value: value,
                      onChanged: _interactive ? (_) {} : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sublabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

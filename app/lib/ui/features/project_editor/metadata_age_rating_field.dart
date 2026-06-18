import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 年龄分级：仅可选 Core 预设；未选时占位「未设置」，尾部 ✕ 清空。
class MetadataAgeRatingField extends StatefulWidget {
  const MetadataAgeRatingField({
    super.key,
    required this.label,
    this.hintText,
    required this.controller,
    required this.presets,
    required this.onChanged,
  });

  final String label;
  final String? hintText;
  final TextEditingController controller;
  final List<String> presets;
  final VoidCallback onChanged;

  @override
  State<MetadataAgeRatingField> createState() => _MetadataAgeRatingFieldState();
}

class _MetadataAgeRatingFieldState extends State<MetadataAgeRatingField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant MetadataAgeRatingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _syncFromController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  String? _selectedValue() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return null;
    if (widget.presets.contains(text)) return text;
    return null;
  }

  void _syncFromController() {
    setState(() {});
  }

  void _applySelection(String? value) {
    widget.controller.text = value ?? '';
    widget.onChanged();
    setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedValue();
    final hasValue = selected != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText ?? '未设置',
            ),
            hint: Text(
              widget.hintText ?? '未设置',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            items: widget.presets
                .map(
                  (preset) => DropdownMenuItem<String>(
                    value: preset,
                    child: Text(preset, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _applySelection,
          ),
        ),
        if (hasValue)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              tooltip: '清空',
              onPressed: _clear,
              icon: const Icon(LucideIcons.x),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

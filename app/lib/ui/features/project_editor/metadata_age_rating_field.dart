import 'package:comic_book_maker/ui/core/widgets/app_dropdown_menu.dart';
import 'package:flutter/material.dart';

/// 年龄分级：仅可选 Core 预设；未选时占位「未设置」，可清空。
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

  @override
  Widget build(BuildContext context) {
    return AppDropdownMenu<String>(
      label: widget.label,
      hintText: widget.hintText ?? '未设置',
      value: _selectedValue(),
      clearable: true,
      items: [
        for (final preset in widget.presets)
          AppDropdownMenuItem(value: preset, label: preset),
      ],
      onChanged: _applySelection,
    );
  }
}

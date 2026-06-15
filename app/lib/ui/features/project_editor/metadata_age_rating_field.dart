import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 年龄分级：仅可选 Core 预设；未选时占位「未设置」，尾部 ✕ 清空。
class MetadataAgeRatingField extends StatefulWidget {
  const MetadataAgeRatingField({
    super.key,
    required this.label,
    required this.controller,
    required this.presets,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final List<String> presets;
  final VoidCallback onChanged;

  @override
  State<MetadataAgeRatingField> createState() => _MetadataAgeRatingFieldState();
}

class _MetadataAgeRatingFieldState extends State<MetadataAgeRatingField> {
  late final ValueNotifier<String?> _valueListenable;

  @override
  void initState() {
    super.initState();
    _valueListenable = ValueNotifier(_selectedValue());
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
    _valueListenable.dispose();
    super.dispose();
  }

  String? _selectedValue() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return null;
    if (widget.presets.contains(text)) return text;
    return null;
  }

  void _syncFromController() {
    final next = _selectedValue();
    if (_valueListenable.value != next) {
      _valueListenable.value = next;
    }
  }

  void _applySelection(String? value) {
    widget.controller.text = value ?? '';
    _valueListenable.value = value;
    widget.onChanged();
  }

  void _clear() {
    widget.controller.clear();
    _valueListenable.value = null;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _valueListenable,
      builder: (context, _) {
        final hasValue = _valueListenable.value != null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField2<String>(
                valueListenable: _valueListenable,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: '未设置',
                ),
                hint: Text(
                  '未设置',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                items: widget.presets
                    .map(
                      (preset) => DropdownItem<String>(
                        value: preset,
                        child: Text(
                          preset,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _applySelection,
              ),
            ),
            if (hasValue)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppIconButton(
                  tooltip: '清空',
                  onPressed: _clear,
                  icon: const Icon(LucideIcons.x),
                ),
              ),
          ],
        );
      },
    );
  }
}

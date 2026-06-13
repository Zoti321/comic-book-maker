import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Canonical `published_date` 年 / 月 / 日三栏输入。
class MetadataPublishedDateField extends StatelessWidget {
  const MetadataPublishedDateField({
    super.key,
    required this.label,
    required this.yearController,
    required this.monthController,
    required this.dayController,
    required this.yearFocusNode,
    required this.monthFocusNode,
    required this.dayFocusNode,
    required this.onChanged,
    this.onEditingComplete,
  });

  final String label;
  final TextEditingController yearController;
  final TextEditingController monthController;
  final TextEditingController dayController;
  final FocusNode yearFocusNode;
  final FocusNode monthFocusNode;
  final FocusNode dayFocusNode;
  final VoidCallback onChanged;
  final VoidCallback? onEditingComplete;

  static String? _validateYear(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return '请输入整数';
    if (parsed < 1000 || parsed > 9999) return '范围 1000–9999';
    return null;
  }

  static String? _validateMonth(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return '请输入整数';
    if (parsed < 1 || parsed > 12) return '范围 1–12';
    return null;
  }

  static String? _validateDay(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return '请输入整数';
    if (parsed < 1 || parsed > 31) return '范围 1–31';
    return null;
  }

  String? _validateMonthRequiresYear(String? value) {
    final monthText = value?.trim() ?? '';
    if (monthText.isEmpty) return null;
    if (yearController.text.trim().isEmpty) {
      return '填写月/日前请先填写年';
    }
    return _validateMonth(value);
  }

  String? _validateDayRequiresMonth(String? value) {
    final dayText = value?.trim() ?? '';
    if (dayText.isEmpty) return null;
    if (monthController.text.trim().isEmpty) {
      return '填写日前请先填写月';
    }
    return _validateDay(value);
  }

  Widget _partField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String partLabel,
    required String? Function(String? value) validator,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: partLabel),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: validator,
        onChanged: (_) => onChanged(),
        onEditingComplete: onEditingComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _partField(
              controller: yearController,
              focusNode: yearFocusNode,
              partLabel: '年',
              validator: _validateYear,
            ),
            const SizedBox(width: 12),
            _partField(
              controller: monthController,
              focusNode: monthFocusNode,
              partLabel: '月',
              validator: _validateMonthRequiresYear,
            ),
            const SizedBox(width: 12),
            _partField(
              controller: dayController,
              focusNode: dayFocusNode,
              partLabel: '日',
              validator: _validateDayRequiresMonth,
            ),
          ],
        ),
      ],
    );
  }
}

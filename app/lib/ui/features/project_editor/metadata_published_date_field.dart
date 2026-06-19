import 'package:comic_book_maker/ui/core/widgets/app_field_suffix_icon_button.dart';
import 'package:flutter/material.dart';

/// Canonical `published_date`：Material 日历选择完整日期；Import 的 partial 仅作中文展示。
class MetadataPublishedDateField extends StatelessWidget {
  const MetadataPublishedDateField({
    super.key,
    required this.label,
    required this.yearController,
    required this.monthController,
    required this.dayController,
    required this.onChanged,
    this.onEditingComplete,
  });

  final String label;
  final TextEditingController yearController;
  final TextEditingController monthController;
  final TextEditingController dayController;
  final VoidCallback onChanged;
  final VoidCallback? onEditingComplete;

  static final firstPickerDate = DateTime(1000, 1, 1);
  static final lastPickerDate = DateTime(9999, 12, 31);

  static String? formatDisplayText({
    required String year,
    required String month,
    required String day,
  }) {
    final yearText = year.trim();
    if (yearText.isEmpty) return null;

    final monthText = month.trim();
    final dayText = day.trim();
    if (monthText.isEmpty) return '$yearText年';
    if (dayText.isEmpty) return '$yearText年$monthText月';
    return '$yearText年$monthText月$dayText日';
  }

  static DateTime initialPickerDate({
    required String year,
    required String month,
    required String day,
    DateTime? fallback,
  }) {
    final yearValue = int.tryParse(year.trim());
    if (yearValue == null) {
      return clampPickerDate(fallback ?? DateTime.now());
    }

    final monthValue = int.tryParse(month.trim());
    final dayValue = int.tryParse(day.trim());
    if (monthValue != null && dayValue != null) {
      return clampPickerDate(DateTime(yearValue, monthValue, dayValue));
    }
    if (monthValue != null) {
      return clampPickerDate(DateTime(yearValue, monthValue, 1));
    }
    return clampPickerDate(DateTime(yearValue, 1, 1));
  }

  static DateTime clampPickerDate(DateTime value) {
    if (value.isBefore(firstPickerDate)) return firstPickerDate;
    if (value.isAfter(lastPickerDate)) return lastPickerDate;
    return value;
  }

  static String? validateParts({
    required String year,
    required String month,
    required String day,
  }) {
    final yearText = year.trim();
    final monthText = month.trim();
    final dayText = day.trim();

    if (yearText.isEmpty && monthText.isEmpty && dayText.isEmpty) {
      return null;
    }

    if (yearText.isEmpty) {
      return '填写月/日前请先填写年';
    }
    final parsedYear = int.tryParse(yearText);
    if (parsedYear == null) return '请输入有效年份';
    if (parsedYear < 1000 || parsedYear > 9999) return '范围 1000–9999';

    if (monthText.isEmpty && dayText.isEmpty) return null;

    if (monthText.isEmpty) {
      return '填写日前请先填写月';
    }
    final parsedMonth = int.tryParse(monthText);
    if (parsedMonth == null) return '请输入有效月份';
    if (parsedMonth < 1 || parsedMonth > 12) return '范围 1–12';

    if (dayText.isEmpty) return null;

    final parsedDay = int.tryParse(dayText);
    if (parsedDay == null) return '请输入有效日期';
    if (parsedDay < 1 || parsedDay > 31) return '范围 1–31';

    return null;
  }

  void _applyPickerDate(DateTime picked) {
    yearController.text = picked.year.toString();
    monthController.text = picked.month.toString();
    dayController.text = picked.day.toString();
    onChanged();
    onEditingComplete?.call();
  }

  void _clearDate() {
    yearController.clear();
    monthController.clear();
    dayController.clear();
    onChanged();
    onEditingComplete?.call();
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDate: initialPickerDate(
        year: yearController.text,
        month: monthController.text,
        day: dayController.text,
      ),
      firstDate: firstPickerDate,
      lastDate: lastPickerDate,
    );
    if (picked == null || !context.mounted) return;
    _applyPickerDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        yearController,
        monthController,
        dayController,
      ]),
      builder: (context, _) {
        final displayText = formatDisplayText(
          year: yearController.text,
          month: monthController.text,
          day: dayController.text,
        );
        final hasValue = displayText != null;

        return FormField<void>(
          validator: (_) => validateParts(
            year: yearController.text,
            month: monthController.text,
            day: dayController.text,
          ),
          builder: (field) {
            return InkWell(
              onTap: () => _openDatePicker(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  errorText: field.errorText,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasValue)
                        AppFieldSuffixIconButton(
                          tooltip: '清空',
                          icon: Icons.close,
                          onPressed: _clearDate,
                        ),
                      if (hasValue)
                        const SizedBox(width: AppFieldSuffixIconButton.gap),
                      AppFieldSuffixIconButton(
                        tooltip: '选择日期',
                        icon: Icons.calendar_today,
                        onPressed: () => _openDatePicker(context),
                      ),
                    ],
                  ),
                ),
                child: Text(
                  displayText ?? '未设置',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: hasValue
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

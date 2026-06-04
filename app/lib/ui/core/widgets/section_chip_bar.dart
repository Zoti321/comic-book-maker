import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class SectionChipBar extends StatelessWidget {
  const SectionChipBar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(sections[i]),
                selected: selectedIndex == i,
                onSelected: (_) => onSelected(i),
                showCheckmark: false,
                selectedColor: scheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: selectedIndex == i
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight:
                      selectedIndex == i ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selectedIndex == i
                      ? scheme.primary.withValues(alpha: 0.35)
                      : scheme.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdBorder,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

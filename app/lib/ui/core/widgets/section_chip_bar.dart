import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:flutter/material.dart';

class SectionChipBar extends StatelessWidget {
  const SectionChipBar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
    this.expandOnCompact = true,
  });

  final List<String> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool expandOnCompact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final segmented = SegmentedButton<int>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BorderSide(
            color: selected ? scheme.onSurfaceVariant : scheme.outline,
          );
        }),
      ),
      segments: [
        for (var i = 0; i < sections.length; i++)
          ButtonSegment<int>(value: i, label: Text(sections[i])),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onSelected(selection.first);
      },
    );

    if (expandOnCompact && isCompact(context)) {
      return SizedBox(width: double.infinity, child: segmented);
    }

    return Align(alignment: Alignment.centerLeft, child: segmented);
  }
}

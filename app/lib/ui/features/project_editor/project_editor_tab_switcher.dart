import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_app_bar.dart';
import 'package:flutter/material.dart';

/// 编辑页 Tab：图片 / 元数据（分段按钮，非 [TabBar]）。
class ProjectEditorTabSwitcher extends StatelessWidget {
  const ProjectEditorTabSwitcher({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.trailing,
  });

  final ProjectEditorTab selectedTab;
  final ValueChanged<ProjectEditorTab> onTabSelected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tabControl = SegmentedButton<ProjectEditorTab>(
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
      segments: const [
        ButtonSegment(
          value: ProjectEditorTab.images,
          label: Text('图片'),
          icon: Icon(Icons.photo_library_outlined, size: 18),
        ),
        ButtonSegment(
          value: ProjectEditorTab.metadata,
          label: Text('元数据'),
          icon: Icon(Icons.description_outlined, size: 18),
        ),
      ],
      selected: {selectedTab},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onTabSelected(selection.first);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailing = isCompact(context) && trailing != null;

        if (stackTrailing) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tabControl,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: trailing!,
              ),
            ],
          );
        }

        return Row(
          children: [
            Flexible(child: tabControl),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

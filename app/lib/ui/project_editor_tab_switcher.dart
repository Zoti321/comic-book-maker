import 'package:comic_book_maker/ui/project_editor_app_bar.dart';

import 'package:flutter/material.dart';



/// 编辑页 Tab：图片 / 元数据（分段小按钮，非 [TabBar]）。

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

    return Row(

      children: [

        SegmentedButton<ProjectEditorTab>(

          style: ButtonStyle(

            visualDensity: VisualDensity.compact,

            tapTargetSize: MaterialTapTargetSize.shrinkWrap,

            padding: WidgetStateProperty.all(

              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

            ),

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

        ),

        if (trailing != null) ...[

          const SizedBox(width: 8),

          trailing!,

        ],

      ],

    );

  }

}



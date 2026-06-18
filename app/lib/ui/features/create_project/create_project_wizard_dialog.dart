import 'package:comic_book_maker/ui/core/shell/side_tab_feature_dialog.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 宽屏新建项目对话框向导。
class CreateProjectWizardDialog extends HookConsumerWidget {
  const CreateProjectWizardDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState(0);
    final wizard = useCreateProjectWizardState();

    return ListenableBuilder(
      listenable: wizard.draft,
      builder: (context, _) {
        final current = wizard.current;
        return SideTabFeatureDialog(
          title: '新建项目',
          tabs: createProjectWizardTabs,
          selectedIndex: tabIndex.value,
          onTabSelected: (index) => tabIndex.value = index,
          body: SingleChildScrollView(
            child: CreateProjectWizardTabPanel(
              tabIndex: tabIndex.value,
              state: wizard,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: current.canCreate
                  ? () => Navigator.pop(context, wizard.finalizedDraft())
                  : null,
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
}

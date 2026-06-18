import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_dialog.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_body.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 宽屏新建项目对话框向导。
class CreateProjectWizardDialog extends HookConsumerWidget {
  const CreateProjectWizardDialog({
    super.key,
    required this.coordinator,
    required this.dialogContext,
  });

  final SideTabFeatureCoordinator<CreateProjectDraft> coordinator;
  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = useCreateProjectWizardState(ref);

    return ListenableBuilder(
      listenable: wizard.draft,
      builder: (context, _) {
        final current = wizard.current;
        return SideTabFeatureDialog(
          title: '新建项目',
          tabs: createProjectWizardTabs,
          selectedIndex: wizard.tabIndex,
          onTabSelected: (index) {
            wizard.setTabIndex(index);
            coordinator.tabIndex = index;
          },
          body: CreateProjectWizardTabPanel(
            tabIndex: wizard.tabIndex,
            state: wizard,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: current.canCreate
                  ? () => Navigator.pop(
                        dialogContext,
                        wizard.finalizedDraft(),
                      )
                  : null,
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
}

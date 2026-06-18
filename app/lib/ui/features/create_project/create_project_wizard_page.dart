import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_page.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_body.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 窄屏新建项目全页向导。
class CreateProjectWizardPage extends ConsumerWidget {
  const CreateProjectWizardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator =
        SideTabFeatureCoordinator.of<CreateProjectDraft>(context);
    final wizard = useCreateProjectWizardState(ref);

    void onTabSelected(int index) {
      wizard.setTabIndex(index);
      coordinator?.tabIndex = index;
    }

    void cancel() => context.pop<CreateProjectDraft?>(null);

    void submit() {
      if (!wizard.canCreate) return;
      context.pop(wizard.finalizedDraft());
    }

    final page = SideTabFeaturePage(
      title: '新建项目',
      tabs: createProjectWizardTabs,
      initialTabIndex: wizard.tabIndex,
      onTabSelected: onTabSelected,
      tabBodies: [
        for (var i = 0; i < createProjectWizardTabs.length; i++)
          sideTabFeaturePageTabBody(
            CreateProjectWizardTabPanel(tabIndex: i, state: wizard),
          ),
      ],
      bottomNavigationBar: ListenableBuilder(
        listenable: wizard.draft,
        builder: (context, _) => sideTabFeaturePageActionBar(
          onCancel: cancel,
          primaryLabel: '创建',
          onPrimary: wizard.canCreate ? submit : null,
        ),
      ),
    );

    if (coordinator == null) {
      return page;
    }

    coordinator.popCompactPage = () => context.pop();

    return SideTabFeaturePagePresentation(
      coordinator: coordinator,
      child: page,
    );
  }
}

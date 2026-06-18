import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_host.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_page.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_body.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 新建项目向导（对话框 / 全页统一入口）。
class CreateProjectWizardFeature extends HookConsumerWidget {
  const CreateProjectWizardFeature({
    super.key,
    this.coordinator,
    this.closeContext,
    this.form = SideTabMorphForm.page,
  });

  final SideTabFeatureCoordinator<CreateProjectDraft>? coordinator;
  final BuildContext? closeContext;
  final SideTabMorphForm form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCoordinator =
        coordinator ?? SideTabFeatureCoordinator.of<CreateProjectDraft>(context);
    final wizard = useCreateProjectWizardState(ref);
    final closeCtx = closeContext ?? context;

    void onTabSelected(int index) {
      wizard.setTabIndex(index);
      activeCoordinator?.tabIndex = index;
    }

    void close([CreateProjectDraft? result]) {
      if (form == SideTabMorphForm.dialog) {
        Navigator.pop(closeCtx, result);
      } else {
        context.pop(result);
      }
    }

    final host = ListenableBuilder(
      listenable: wizard.draft,
      builder: (context, _) {
        return SideTabFeatureHost(
          spec: SideTabFeatureSpec(
            title: '新建项目',
            tabs: createProjectWizardTabs,
            tabBodyBuilder: (_, tabIndex) => CreateProjectWizardTabPanel(
              tabIndex: tabIndex,
              state: wizard,
            ),
          ),
          form: form,
          tabIndex: wizard.tabIndex,
          onTabSelected: onTabSelected,
          dialogActions: [
            TextButton(
              onPressed: () => close(null),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: wizard.canCreate
                  ? () => close(wizard.finalizedDraft())
                  : null,
              child: const Text('创建'),
            ),
          ],
          pageBottomBar: sideTabFeaturePageActionBar(
            onCancel: () => close(null),
            primaryLabel: '创建',
            onPrimary: wizard.canCreate ? () => close(wizard.finalizedDraft()) : null,
          ),
        );
      },
    );

    if (activeCoordinator == null) {
      return host;
    }

    return SideTabMorphPresentation(
      coordinator: activeCoordinator,
      form: form,
      child: host,
    );
  }
}

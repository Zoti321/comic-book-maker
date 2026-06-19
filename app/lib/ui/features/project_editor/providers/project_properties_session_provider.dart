import 'package:comic_book_maker/ui/core/shell/side_tab_feature_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProjectPropertiesSessionData {
  const ProjectPropertiesSessionData({required this.tabIndex});

  final int tabIndex;
}

class ProjectPropertiesSessionNotifier
    extends Notifier<ProjectPropertiesSessionData> {
  @override
  ProjectPropertiesSessionData build() {
    return const ProjectPropertiesSessionData(tabIndex: 0);
  }

  void reset() {
    state = const ProjectPropertiesSessionData(tabIndex: 0);
  }

  void setTabIndex(int index) {
    if (state.tabIndex == index) return;
    state = ProjectPropertiesSessionData(tabIndex: index);
  }
}

final projectPropertiesSessionProvider = NotifierProvider<
    ProjectPropertiesSessionNotifier,
    ProjectPropertiesSessionData>(
  ProjectPropertiesSessionNotifier.new,
);

/// [openSideTabFeature] 会话接缝：打开重置 Tab，关闭 invalidate provider。
final projectPropertiesSideTabSession = SideTabFeatureSession.resettable(
  reset: (container) =>
      container.read(projectPropertiesSessionProvider.notifier).reset(),
  invalidate: (container) =>
      container.invalidate(projectPropertiesSessionProvider),
);

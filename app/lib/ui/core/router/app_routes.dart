abstract final class AppRoutes {
  static const projects = '/projects';
  static const settings = '/settings';
  static const projectEditor = '/project/:projectId';

  static String projectEditorPath(String projectId) => '/project/$projectId';
}

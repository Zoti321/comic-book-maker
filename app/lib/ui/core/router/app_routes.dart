abstract final class AppRoutes {
  static const projects = '/projects';
  static const settings = '/settings';
  static const projectCreate = '/projects/create';
  static const projectEditor = '/project/:projectId';
  static const projectProperties = '/project/:projectId/properties';

  static String projectEditorPath(String projectId) => '/project/$projectId';

  static String projectPropertiesPath(String projectId) =>
      '/project/$projectId/properties';
}

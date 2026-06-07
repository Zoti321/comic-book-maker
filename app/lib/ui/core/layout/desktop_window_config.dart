/// 桌面窗口 chrome 启动配置；[configureDesktopWindow] 写入后只读。
class DesktopWindowConfig {
  const DesktopWindowConfig({required this.chromeEnabled});

  /// 无边框 + 自绘标题栏初始化是否成功；失败时为 `false`，使用系统标题栏。
  final bool chromeEnabled;

  static const DesktopWindowConfig disabled = DesktopWindowConfig(
    chromeEnabled: false,
  );
}

/// 应用启动后由 [configureDesktopWindow] 设置的只读配置。
DesktopWindowConfig desktopWindowConfig = DesktopWindowConfig.disabled;

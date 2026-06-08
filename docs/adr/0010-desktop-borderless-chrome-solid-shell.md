# 桌面无边框窗口与实色自绘标题栏

**Status:** accepted  
**Date:** 2026-06-07  
**Supersedes:** [ADR-0009](0009-desktop-frosted-glass-shell.md)

桌面端（Windows、macOS、Linux）采用无边框窗口 + Flutter 自绘窗口 chrome + **实色**壳层。不依赖 DWM Mica/Acrylic、macOS Vibrancy 或 Runner Method Channel 设置系统 backdrop。

## 决策

### 1. 窗口 chrome

- 启动时通过 `window_manager` 在桌面平台尝试 `TitleBarStyle.hidden` 并保留最小窗口尺寸（360×640，见 `configureDesktopWindow()`）；允许缩至 compact 断点（720px）以下，便于桌面端调试窄屏 UI。
- 初始化成功时写入只读配置（如 `desktopWindowConfig.chromeEnabled == true`）；任一步骤失败则**不**隐藏系统标题栏，写入 `chromeEnabled == false`，应用以系统 chrome 正常运行。
- 当 `chromeEnabled == true` 时，根 widget 通过 `DesktopShell` 包裹应用：`VirtualWindowFrame` 支持拖边缩放；顶栏为 `DesktopWindowCaption`（实色 `surface` / `surfaceContainerLow`，**非透明**）。

### 2. 顶栏职责

- **纯窗口 chrome**：应用名 + 拖拽区 + 最小化 / 最大化（或 macOS zoom）/ 关闭。
- **不**合并 Project 编辑页等业务 AppBar；各页面保留现有 Scaffold AppBar 与导航。

### 3. 壳层视觉

- 侧栏、顶栏、窗口背景均使用 `AppTheme` 实色 token；**禁止**壳层透明以透出系统模糊。
- 主内容区继续使用实色 `surface` 面板，与当前 Material 3 设计一致。

### 4. 平台与降级

- 三桌面平台同时交付；macOS 控件位置遵循平台习惯（traffic lights 等）。
- 无边框初始化失败 → 回退系统标题栏，功能与布局与无 chrome 版本一致。
- 不引入 Runner 侧 `desktop_backdrop`、Method Channel `comic_book_maker/desktop_window` 或等价 native backdrop API。

## 备选

- **继续 ADR-0009 毛玻璃方案**：维护成本高、可读性不可控，否决。
- **保留系统标题栏、不做无边框**：与桌面创作工具现代 chrome 目标不符，否决为默认；仍保留失败降级路径。
- **统一顶栏合并业务 AppBar**：首期范围过大，否决。

## 后果

- 正面：单一实色主题源、无 native backdrop 维护、chrome 与内容层职责清晰、可独立 tracer-bullet 交付（issue 02 → 03）。
- 负面：无系统级模糊视觉效果；后续若需局部半透明须另开 ADR，且不得复用整窗 backdrop 方案。
- 验收：issue 01 清理毛玻璃 WIP 与本 ADR 归档；issue 02/03 落地 chrome；issue 04 三平台目视 QA。

**相关：** `.scratch/desktop-borderless-chrome/`、`docs/agents/flutter-ui.md`、`app/lib/ui/core/layout/desktop_window.dart`

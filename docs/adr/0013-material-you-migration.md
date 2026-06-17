# Material You 全面迁移，feature 直用 Material 控件

**Status:** accepted  
**Date:** 2026-06-16  
**Parent PRD:** [GitHub #2](https://github.com/Zoti321/comic-book-maker/issues/2)  
**Revises:** [ADR-0006](0006-m3-design-system-deprecate-shadcn.md)（`design_system` 作为 feature UI 入口的决策）  
**Related:** [ADR-0010](0010-desktop-borderless-chrome-solid-shell.md)（桌面窗口 chrome 结构仍有效）

ADR-0006 将应用从 `shadcn_ui` 迁到 `MaterialApp.router`，并引入自封装 `design_system`（`AppButton`、自绘菜单等）作为**唯一** feature UI 原语层。该层在视觉上仍是 zinc 中性灰 + 非标准 M3 交互（无 Material ripple、非 `FilledButton` 形态），与「专业创作工具应呈现标准 Material Design 体验」不符。

本 ADR 记录 [PRD #2](https://github.com/Zoti321/comic-book-maker/issues/2) 的落地决策：**全面 Material You**，feature 直接使用 Flutter Material 3 控件；视觉与信息架构参考 [Animeko](https://github.com/open-ani/animeko) 的 Material 桌面/平板适配思路（宽屏侧栏导航、设置 Segmented 选项、卡片浏览），**不**移植其 Compose/KMP 代码或引入依赖。

## 决策

### 1. 主题

- 根应用：`MaterialApp.router` + `go_router` + `ProviderScope`（与 ADR-0006 一致）。
- **双主题**：`AppTheme.light()` / `AppTheme.dark()` 均由 `ColorScheme.fromSeed(seedColor: 0xFF1565C0)` 生成 Material You 配色。
- **ThemeMode**：默认 `ThemeMode.system`；设置页三档（跟随系统 / 浅色 / 深色）经 `themeModeProvider` 持久化（`shared_preferences`）。
- 间距、圆角、排版 token 仍用 `app/lib/ui/core/theme/app_tokens.dart`；颜色优先 `Theme.of(context).colorScheme`，勿再依赖固定 zinc primary。

### 2. 导航壳

- 主壳 `AppShell`：宽屏 `NavigationRail`，窄屏 `NavigationBar`（漫画库、设置）。
- 移除自绘 `Sidebar` / `MobileAppNav` 作为主路径。
- **ADR-0010 不变**：`DesktopShell` / `DesktopWindowCaption` 仍负责无边框窗口 chrome（拖拽、最小化/最大化/关闭）；仅配色跟随 `ColorScheme`，不合并业务 AppBar。

### 3. Feature UI

- **`ui/features/**` 禁止** `import` `ui/core/design_system/`。
- 按钮：`FilledButton` / `OutlinedButton` / `TextButton` / `IconButton`。
- 表单：`TextFormField`、`DropdownButtonFormField`、`Checkbox`、`SegmentedButton` 等，样式由 `InputDecorationTheme` 与 `ThemeData` 提供。
- 卡片 / 列表：`Card`、`InkWell`、`PopupMenuButton` / `showMenu`。
- 对话框 / Sheet：`showDialog` + `AlertDialog`、`showModalBottomSheet`；侧栏 Tab 功能对话框用 `SideTabFeatureDialog` + `SideTabDialogShell`（Material `Dialog` 壳）。
- 反馈：`ScaffoldMessenger.showSnackBar`、阻塞 loading 用 `AlertDialog` + `CircularProgressIndicator`（见各 feature 内 helper，如 `project_editor_dialogs.dart`）。
- 空态 / 加载 / 内联错误：feature 内局部 Material 组件（如 `LibraryEmptyState`、`ProjectEditorInlineErrorBanner`），或复用同 feature 的共享 widget；**勿**再经 `design_system` 统一导出。

### 4. 元数据表单控件

- 年龄分级：`MetadataAgeRatingField` 使用 `DropdownButtonFormField`（#9 已替换 `dropdown_button2`）。
- 创作 Tab 逗号标签：`MetadataCommaTagsField` 使用 `InputChip` + `TextField`（#9 已替换 `textfield_tags`）。
- 行为与 Core `mergeMetadataFromForm` 规则不变。

### 5. `design_system` 目录

- ADR-0006 中「feature 必须经 `design_system`」**废止**。
- 目录 `app/lib/ui/core/design_system/` **暂留**根级遗留（如 `AppToastHost`、`desktop_window_caption` 经 `main.dart` / `desktop_shell.dart` 引用）；**不得**作为新 feature 代码入口。后续 issue 可删除整目录或仅保留桌面专用极小模块。

### 6. 与 ADR-0006 / ADR-0010 的关系

| ADR | 关系 |
| --- | --- |
| **0006** | 仍有效：弃用 `shadcn_ui`、`MaterialApp.router`、M3 token。被本 ADR **修订**：`design_system` 不再是 feature 主路径。 |
| **0010** | **完全保留**：无边框窗口、实色标题栏、失败降级；仅 `ColorScheme` 视觉更新。 |

## 备选

- **保留 design_system 并只换主题色**：无法获得 M3 标准交互与导航形态，否决。
- **引入第三方 Material 组件库**：增加依赖与 Agent 学习成本，否决。
- **一次性删除 design_system 含 main 引用**：需同步改 Toast 与桌面 caption，范围过大；分阶段删除，否决为单次交付。

## 后果

- 正面：feature 与 Flutter/Material 文档一致；Agent 与人类只需学 M3 + 本仓库 `flutter-ui.md`；深浅色与系统跟随一次交付。
- 负面：`design_system` 测试与目录仍存直至根级迁移完成。
- 验收：`rg design_system app/lib/ui/features` 无匹配；`flutter test` 全绿；`docs/agents/flutter-ui.md` 与代码一致；本 ADR 与 `docs/README.md` 已索引。

**实现追踪：** GitHub #3–#8（Material You 切片）；合并 PR 后关闭对应 issue。

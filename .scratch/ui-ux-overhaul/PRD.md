# UI/UX 全面优化：专业创作工具风 + Material 3

Status: ready-for-agent

## Problem Statement

Comic Book Maker 功能链路已打通（Library、Project 编辑、Import/Export、Metadata），但全应用仍给人「原型感」：视觉不统一（`shadcn_ui` 与 Material 控件混搭、橙色偏消费向）、信息层级弱；交互上顶栏动作堆叠、导入/导出反馈分散、错误与加载态不一致。用户难以把它当作**专业、可长期使用的创作工具**。

## Solution

分两期交付：

- **Phase 1（视觉基线）**：弃用 `shadcn_ui`，建立 **Material 3 浅色主题**与 **`design_system` 自封装层**（专业工具气质：中性色、紧凑密度、细边框、统一控件高度）。按壳层递进迁移全应用（含 Library、Project 编辑两 Tab、设置、全部 Dialog/Sheet），**桌面 Windows 优先**，移动端 Phase 1 要求不回归。验收：**检查表 + widget 测试**（`FakeRustLibApi`）。
- **Phase 2（交互重构）**：在 Phase 1 组件稳定后，分两批改用户路径——先 **Project 顶栏、Export/追加导入、全局反馈**；再 **Library 导入路径、图片 Tab、元数据 Tab**（Library 是否加强画廊感视情况追加）。

## User Stories

### 视觉与品牌

1. As a 桌面用户, I want the app to look like a professional creative tool, so that I trust it for long editing sessions.
2. As a 桌面用户, I want consistent colors, typography, and spacing across all screens, so that I am not distracted by mismatched controls.
3. As a 桌面 user, I want buttons and inputs to look and behave the same everywhere, so that I learn the interface once.
4. As a 桌面 user, I want dialogs and sheets to match the main app chrome, so that modals feel integrated rather than alien.
5. As a 桌面 user, I want the sidebar and content area to have clear visual hierarchy, so that I always know where I am in the app.
6. As a 移动端 user, I want the app to remain usable after the redesign, so that I can open projects on the go without broken layouts.

### Library

7. As a Library 用户, I want the project list to feel organized and scannable, so that I can find a Project quickly.
8. As a Library 用户, I want empty and loading states to look intentional, so that an empty library does not feel broken.
9. As a Library 用户, I want import and create actions to be visually primary but not chaotic, so that I know how to start work.
10. As a Project 用户, I want project cards to show cover and title clearly, so that I recognize my comics at a glance.

### Project 编辑（Phase 1 视觉）

11. As a Project 用户, I want the editor chrome (title area, tabs, settings strip) to look cohesive, so that editing feels like one workspace.
12. As a Project 用户, I want the 图片 Tab thumbnails to align in a clear grid with readable labels, so that page order and cover are obvious.
13. As a Project 用户, I want the 元数据 Tab form controls to match the rest of the app, so that long forms are tolerable to fill.
14. As a Project 用户, I want disabled PDF-related controls to look clearly inactive, so that I do not confuse placeholders with bugs.

### 设置

15. As a 用户, I want the settings page to use the same design language as Library and editor, so that the app feels finished.

### Phase 2 — Project 顶栏与动作（批次 1）

16. As a Project 用户, I want Export and related actions grouped by importance, so that I am not hunting through a flat AppBar menu.
17. As a Project 用户, I want to understand what Export will do before I commit, so that I do not export the wrong format.
18. As a Project 用户, I want append-import entry points to relate to my Project’s inferred import kind, so that I know what I can add.
19. As a Project 用户, I want project settings (export format) discoverable near but not mixed with destructive/export actions, so that I change format safely.

### Phase 2 — Export / 追加导入（批次 1）

20. As a Project 用户, I want one clear progress and outcome pattern for Export, so that I know when I can leave the app.
21. As a Project 用户, I want default export directory behavior explained in the flow, so that I am not surprised where files land.
22. As a Project 用户, I want import warnings and success to use consistent surfaces, so that I do not miss critical messages.
23. As a Project 用户, I want to cancel or dismiss long operations safely, so that I am not stuck behind blocking UI mistakes.

### Phase 2 — 全局反馈（批次 1）

24. As a 用户, I want errors to appear in a predictable place and style, so that I notice and can dismiss them.
25. As a 用户, I want loading indicators to look the same for FRB calls and file pickers, so that I know the app is working.
26. As a 用户, I want empty states to suggest the next action, so that I am never staring at a blank panel without guidance.
27. As a 用户, I want success feedback (toast/snackbar) to be brief and non-blocking, so that confirmations do not interrupt flow.

### Phase 2 — Library 导入路径（批次 2）

28. As a Library 用户, I want control over whether import immediately opens the editor, so that bulk import does not disorient me.
29. As a Library 用户, I want import progress visible for large archives, so that I do not think the app froze.
30. As a Library 用户, I want import errors recoverable from the Library screen, so that I can retry without restarting.

### Phase 2 — 图片 Tab（批次 2）

31. As a Project 用户, I want page operations (replace, delete, set cover) reachable from one consistent pattern, so that I do not hunt context menus.
32. As a Project 用户, I want cover page visually distinct on the grid, so that export cover matches my intent.
33. As a Project 用户, I want reordering pages to match my mental model (if supported), so that reading order is easy to fix.
34. As a Project 用户, I want adding pages to be obvious when the grid is non-empty, so that I do not scroll looking for an add button.

### Phase 2 — 元数据 Tab（批次 2）

35. As a Project 用户, I want section navigation that reflects ComicInfo/OPF structure, so that I find fields without reading everything.
36. As a Project 用户, I want dirty/saved state obvious before I leave the tab, so that I do not lose metadata edits.
37. As a Project 用户, I want import metadata preview related to editable fields, so that I understand what came from the archive.
38. As a Project 用户, I want save failures surfaced next to the form, so that I can fix validation without guessing.

### Phase 2 — 可选画廊化 Library（视情况）

39. As a Library 用户, I want larger cover-forward project tiles, so that browsing feels like a collection (only if batch 2 adopts gallery emphasis).

### 开发者 / 维护

40. As a 维护者, I want pages to depend only on `design_system` for UI primitives, so that future theme changes are localized.
41. As a 维护者, I want widget tests on critical paths, so that UI refactors do not silently break Library or editor entry.
42. As a 维护者, I want `shadcn_ui` removed from dependencies after Phase 1, so that we do not maintain two component systems.

## Implementation Decisions

### 总体

- **范围**：全应用 UI（Library、Project 编辑含图片/元数据 Tab、设置、Import/Export/Append 相关 Dialog 与 Sheet、侧栏壳层）。**不**改 Core FRB 领域 API，除非 Phase 2 交互明确需要（优先纯 UI 状态机）。
- **分期**：Phase 1 视觉；Phase 2 交互。Phase 2 顺序：**2 → 5 → 7**，再 **1 → 3 → 4**；批次 2 的 Library 是否加强画廊感（大封面、留白）**届时再定**。
- **平台**：Phase 1 **浅色主题 only**；深色主题 Out of Scope。 **桌面优先**（Windows 为主验收环境）；移动端 Phase 1 以「布局不破、主要操作可达」为底线。
- **气质**：专业创作工具 — 中性背景、紧凑垂直节奏、弱装饰、强调信息密度与对齐；**不**追求消费级大面积橙色，强调色仅用于 primary 行动点。

### Phase 1 — Material 3 与 design_system

- **根应用**：`ShadApp.router` 替换为 **`MaterialApp.router`**（或等价 M3 入口），保留 `go_router` 与 `ProviderScope`；locale 与现有中文 UI 文案不变。
- **主题模块**：扩展 `AppTheme`（或等价）为 M3 `ThemeData` + `ColorScheme`（浅色），定义 **spacing / radius / elevation / typography** token（桌面略紧凑，如 4/8/12/16 栅格、统一 `InputDecoration` 与 `FilledButton`/`OutlinedButton` 高度）。
- **design_system 层**（新建）：对外暴露稳定 API，例如 `AppButton`、`AppIconButton`、`AppTextField`、`AppDialog`、`AppSheet`、`AppSnackBar`、`AppCard`、`AppSectionHeader`、`AppLoadingOverlay` 等；**页面与 feature 代码禁止直接 import 旧 Shad 组件**。
- **迁移策略（壳层递进 B）**：
  1. Theme + design_system 基础 + 根 widget 切换
  2. AppShell、侧栏、导航 chrome、全局 toast/dialog 封装
  3. 所有共享 Dialog/Sheet（Import、Export CBZ/EPUB、Append）
  4. Library 页
  5. Project 编辑壳层、设置条、图片 Tab、元数据 Tab
  6. 设置页
  7. 从 `pubspec` **移除 `shadcn_ui`**，全仓无 Shad import；更新 `docs/agents/flutter-ui.md` 为 M3 + design_system 约定
- **侧栏**：保留现有自封装 `Sidebar` 结构，用 M3 颜色与 `design_system` 菜单项重皮肤；不强制改为 Material `NavigationRail` 除非实现更简单。
- **元数据 Tab**：仍由 Core `metadata_schema` 驱动字段；Phase 1 只替换控件皮肤与布局间距，**不**改合并/保存规则。
- **ADR**：建议新增一篇 ADR 记录「弃用 shadcn_ui，采用 M3 + design_system」（实现时由执行 issue 写入 `docs/adr/`）。

### Phase 2 — 交互（概要，细节在子 issue）

- **批次 1（2, 5, 7）**
  - **Project 顶栏**：按「主要/次要/危险」分组 Export、追加导入、返回；与 `export_format` / `inferred_import_kind` 联动禁用态与说明；减少平铺图标。
  - **Export / 追加导入**：统一多步流（选路径 → 执行 → 结果）；合并 Toast、Dialog、blocking loading 为单一模式；默认导出目录提示一致。
  - **全局反馈**：统一 `InlineErrorBanner`、空状态、loading 为 design_system 组件；定义何时用 SnackBar vs Dialog vs 内联。
- **批次 2（1, 3, 4，+ 可选画廊 D）**
  - **Library 导入**：评估导入后是否自动 `push` 编辑页；大文件 loading；错误恢复。
  - **图片 Tab**：统一页面操作入口；封面标识；若 Core 已有 reorder API 则补拖拽或明确排序 UI。
  - **元数据 Tab**：分段与 dirty/saved 更明显；导入预览与字段关系；保存错误贴近表单。

### 模块清单（构建/修改）

| 模块 | Phase | 职责 |
|------|-------|------|
| 根应用入口 | 1 | M3 主题注入、router |
| Theme / tokens | 1 | 颜色、字体、间距、组件主题 |
| design_system | 1 | 对外 UI 原语，隔离 M3 细节 |
| AppShell + 侧栏 | 1 | 导航 chrome |
| 共享 Dialog/Sheet/Toast | 1 | Import/Export/Append、alert |
| Library 页 | 1 视觉 / 2 交互 | 项目列表与导入入口 |
| Project 编辑页 | 1 视觉 / 2 交互 | 顶栏、Tab、工作区 |
| 图片 Tab | 1 视觉 / 2 交互 | Page 网格与操作 |
| 元数据 Tab | 1 视觉 / 2 交互 | schema 驱动表单 |
| 设置页 | 1 | 导出路径等 |
| Widget 测试与 harness | 1 | 回归主路径 |
| flutter-ui 文档 | 1 | /agent 约定 |

## Testing Decisions

### 原则

- 测**可观察行为**（是否渲染关键文案、按钮可点、Tab 切换、空态文案），不断言具体 M3 内部实现。
- UI 测试继续 **不加载 Rust FFI**，使用现有 **`FakeRustLibApi`** / `initRustTestFake`。
- **不做** Phase 1 强制 golden screenshot（除非后续单独立项）。

### Phase 1 覆盖（建议）

| 模块 | 测什么 |
|------|--------|
| Library | 空库文案、新建/导入入口存在 |
| Project 编辑 | 从路由 extra 进入后 Tab 存在；图片 Tab 空态或页数文案 |
| 元数据 Tab | ComicArchive / EPUB schema 标题渲染（沿用 fixture schema） |
| 壳层 | 无 `shadcn_ui` import 的静态检查可放在 CI 脚本或 checklist |

### 验收检查表（Phase 1 人工 + 自动）

- [x] `pubspec` 无 `shadcn_ui`；`app/lib` 无 `package:shadcn_ui` import
- [x] `MaterialApp.router` + M3 light theme 生效
- [x] Library、Project 编辑（两 Tab）、设置、Import/Export/Append 弹层均使用 design_system
- [x] 桌面 Windows：1280×800 与更宽窗口下无严重 overflow（widget 测试覆盖）
- [x] 移动端：底栏导航仍可切换项目/设置（widget 测试覆盖）
- [x] `flutter test` 通过（含新增/更新的 widget tests）

### Prior art

- `app/test/support/rust_fake.dart`
- `app/test/widget_test.dart`、`metadata_panel_test.dart`
- `app/test/support/metadata_panel_harness.dart`

## Out of Scope

- 深色主题（后续单独立项）
- 更换为非 M3 的其它 UI 库（已选定 M3；不再评估 Fluent 等，除非 Phase 1 失败另开 ADR）
- Core / FRB 新 API（Phase 2 默认 UI-only；若 reorder 等已存在则只用）
- PDF Import/Export 实现
- Page Image 像素编辑
- Web 客户端
- 全站 golden / Figma 交付物（除非维护者另行提供）
- Phase 2 批次 2 的 Library 画廊化（**可选**，非承诺）

## Further Notes

-  grill 决策摘要：全应用 D；Phase1 视觉 + Phase2 交互；气质 C；M3 弃 Shad；浅色+桌面优先；Phase2 顺序 2,5,7 → 1,3,4；迁移策略 B；验收 C。
- Phase 1 完成后代码库应只有 **一套** UI 原语（design_system），便于 Agent 与人类 review。
- 实现 issue 见 `.scratch/ui-ux-overhaul/issues/`，按编号顺序依赖执行。

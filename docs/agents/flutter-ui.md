# Flutter UI 约定

## 目录与 FRB 边界

Flutter 侧目录与 Core 接缝以 **`docs/adr/0007-flutter-layered-lib-frb-boundary.md`** 为准（分层迁移已完成）。

要点：

- **目标树**：`data/repositories/`（`CoreGateway`）→ `domain/use_cases/` → `ui/core/` + `ui/features/{library,create_project,project_editor,settings}/`。
- **Provider 放置**（见 ADR-0007 §4）：
  - **全局** `lib/providers/`：`coreGatewayProvider`、`exportPathProvider`（Library、Project 编辑、Settings 共用）
  - **Library** `ui/features/library/providers/`：`libraryOperationsProvider`、`libraryProjectsProvider`
  - **Project 编辑** `ui/features/project_editor/providers/`：`projectWorkspaceProvider` family、`ProjectWorkspaceState`
  - `create_project` / `settings` 无独立 Notifier 文件；设置页仅读 `exportPathProvider`
- **FRB 生成物**：仅 `app/lib/src/rust/`（`flutter_rust_bridge.yaml` 的 `dart_output`）；**禁止**在 `ui/`、`providers/` 中 `import package:comic_book_maker/src/rust/...`（`main.dart` 初始化与 `data/repositories` 实现除外）。
- **Rust API**：手写入口在 `core/src/api/`（`rust_input: crate::api`），与 FRB 官方目录约定一致。
- **新增 Core 能力**：改 Rust API → FRB codegen → 扩展 `CoreGateway`，勿在 Widget 直调 FRB。

验收（架构迁移完成后）：`rg 'src/rust' app/lib/ui app/lib/providers` 无匹配。本地/CI 可跑 `scripts/check-frb-ui-isolation.ps1`（Windows）或 `scripts/check-frb-ui-isolation.sh`（Linux/CI）。

## 主题与 Material You

Material You 全面迁移见 **[ADR-0013](../adr/0013-material-you-migration.md)**；UI 动效见 **[ADR-0014](../adr/0014-ui-motion-infrastructure.md)**。视觉参考 [Animeko](https://github.com/open-ani/animeko) 的 M3 桌面/平板信息架构，**不**移植其代码。

- 根应用：`MaterialApp.router` + `go_router` + `ProviderScope`（`app/lib/main.dart`、`app/lib/ui/core/router/`）
- **双主题**：`AppTheme.light()` / `AppTheme.dark()`，均由 `ColorScheme.fromSeed(seedColor: 0xFF1565C0)` 生成
- **ThemeMode**：`themeModeProvider`（`shared_preferences`）持久化；设置页 `SegmentedButton` 三档（跟随系统 / 浅色 / 深色）
- 间距、圆角、排版 token：`app/lib/ui/core/theme/app_tokens.dart`；颜色优先 `Theme.of(context).colorScheme`
- **输入框视觉**：全局 `InputDecorationTheme` 为 M3 Outlined（无填充底色）；水平 `16px`；目标容器高度 **56px**（`AppTypography.controlHeightForm`，与 M3 Specs 一致；Flutter 实现用 `vertical: 20` + `suffixIconConstraints` 达到该高度）；**M3 浮动 label**
- **Ink 反馈**：`AppTheme` 全局 `splashFactory: InkSparkle.splashFactory`（按钮、导航、表单等控件级交互）；大面积卡片式 surface（库卡片、图片 Tab 缩略图/添加页格）用 `AppSurfaceInkWell`（`NoSplash` + preset overlay，见下表）
- **表单 suffix 按钮**：元数据等字段尾部操作用 `AppFieldSuffixIconButton`（36×36 圆形、`Icon` 20px）；`AppDropdownMenu(clearable)` 为「清空 + 4px + 下拉箭头」分区布局
- **Motion**：时长/曲线见 `AppDurations` / `AppCurves`；**必须**经 `AppMotion` 读取 `MediaQuery.disableAnimations`（为 true 时 `Duration.zero`）。全屏路由用 `fadeTransitionPage`（纯 fade，`pageTransition` 200ms）；壳内 Tab 无过渡。Dialog / BottomSheet 统一 `showAppOverlayDialog` / `showAppBottomSheet`（scale 0.96 + fade，`motionNormal` 250ms，见 `app_overlay_transitions.dart`）；**禁止** feature 直接 `showDialog` / `showModalBottomSheet`。组件级动效优先 `flutter_animate`（`staggerEntrance` / `fadeEntrance` 见 `app_motion_effects.dart`）；`animated_text_kit` 仅空态等短标题（见 ADR-0014）。漫画库网格**仅首次有项目时** stagger 入场，排序/增删不重播
- **下拉菜单**：`AppTheme` 配置 `dropdownMenuTheme`；业务侧统一用 `AppDropdownMenu`（菜单与锚点字段**同宽**、项文字 **ellipsis**、`clearable` 清空在字段内 suffix）
- **桌面窗口 chrome**：[ADR-0010](../adr/0010-desktop-borderless-chrome-solid-shell.md) 仍有效：`DesktopShell` + `DesktopWindowCaption`（无边框、实色标题栏）

## 导航壳

主壳 `AppShell`（`ui/core/shell/app_shell.dart`）：

| 断点 | 组件 | 说明 |
| ---- | ---- | ---- |
| 宽屏 | `AppNavigationRail` | 扩展标签 `NavigationRail`；目的地见 `app_navigation_destinations.dart` |
| 窄屏 | `AppNavigationBar` | 底部 `NavigationBar` |

业务内容在 `NavigationRail` 右侧或 `NavigationBar` 上方的主内容区；**勿**再使用已移除的自绘 `Sidebar` / `MobileAppNav`。

布局仍可用 `Scaffold`、`CustomScrollView`、`TabBar` / `TabBarView`。

## Feature UI：直用 Material 3

**`ui/features/**` 禁止** `import` `ui/core/design_system/`。

| 场景 | Material API / 本仓库组件 |
| ---- | ------------------------- |
| 主 / 次 / 文字按钮 | `FilledButton`、`OutlinedButton`、`TextButton` |
| 图标按钮 | `IconButton`（`tooltip` 按需） |
| 单行 / 多行输入 | `TextFormField` + `InputDecorationTheme` |
| 下拉 | `AppDropdownMenu`（`ui/core/widgets/app_dropdown_menu.dart`；继承表单 56px 与 Outlined 主题；弹出菜单与字段同宽） |
| 勾选 | `Checkbox`（常与 `Row` + `Text` 组合） |
| 卡片 / 可点列表项 | `Card` + `AppSurfaceInkWell`（`libraryCard` preset：hover 8%、按下 12%，无 ripple）；密 grid 表面用 `gridTile` preset（仅按下 8%） |
| 锚点菜单 | `PopupMenuButton` 或 `showMenu` |
| 对话框 | `showAppOverlayDialog` + `AlertDialog` / `AppDialog`（scale+fade 入场） |
| 底部 Sheet | `showAppBottomSheet`（scale+fade 入场） |
| 侧栏 Tab 功能对话框 | `SideTabFeatureDialog` + `SideTabDialogShell`（`ui/core/shell/side_tab_feature_dialog.dart`） |
| 短时反馈 | [`showAppSnackBar`](../../app/lib/ui/core/feedback/app_snack_bar.dart)（`ui/core/feedback/`） |
| 阻塞长任务 | `AlertDialog` + `CircularProgressIndicator`（见 `project_editor_dialogs.dart` 等 feature helper） |

### 遗留 `design_system`

`app/lib/ui/core/design_system/` **暂留**根级引用（如 `main.dart` 的 `AppToastHost`、`desktop_shell.dart` 的窗口 caption 辅助）。**新 feature 代码不得依赖**；后续 issue 可删除整目录。弃用 `shadcn_ui` 的决策仍见 [ADR-0006](../adr/0006-m3-design-system-deprecate-shadcn.md)（feature 入口已由 ADR-0013 修订）。

## 页面顶栏

漫画库、设置等主壳页面共用 `PageHeader`（`ui/core/widgets/page_header.dart`）：

- **高度**：标题行 `minHeight` 与 `AppTypography.controlHeightCompact` 对齐（`32px`）；宽屏单行时与无 `actions` 页同高；窄屏折行时允许增高。
- **内边距**：水平跟随 `AppSpacing.pagePadding`，上下对称 `16px`。
- **层次**：`AppElevation.headerShadow` 底部轻阴影；不使用 `outline` 底边线。

## 状态与路由

与既有约定一致：

- `go_router` 声明式路由
- `flutter_riverpod` / `hooks_riverpod` 全局状态
- `HookConsumerWidget` / `HookWidget` 管理局部状态，避免 `StatefulWidget`

## Riverpod 代码生成

新增或修改 `@Riverpod` provider 时，**优先使用 `riverpod_generator` 生成样板代码**，手写 `NotifierProvider` / family 声明仅作例外。

### 写法

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';

@Riverpod(keepAlive: true)
class MyFeature extends _$MyFeature {
  @override
  MyState build() => MyState.initial();

  void doSomething() { /* ... */ }
}
```

- 源文件顶部：`part '…g.dart';`
- Notifier 类继承生成基类 `_$MyFeature`
- family 参数写在 `build` 方法签名上，例如 `build(String projectId)`
- `@Riverpod(keepAlive: true)` 对应全局常驻；默认 `keepAlive: false` 为 autoDispose

### 生成命令

因 `flutter_test` 与 `riverpod_generator` 的 `analyzer` 约束冲突，**在 app 根目录直接跑 `build_runner` 可能失败**。请使用独立工作区（**只改**上表三处应用内源目录，勿维护 `tool/riverpod_codegen/lib/*` 下的拷贝）：

```powershell
# Windows
.\app\tool\riverpod_codegen\run_codegen.ps1
```

```bash
# macOS / Linux
./app/tool/riverpod_codegen/run_codegen.sh
```

脚本将 `tool/riverpod_codegen/lib/{global_providers,library_feature_providers,project_editor_feature_providers}` 分别联接 / 链接到上述三处源目录，运行 `build_runner` 后 `*.g.dart` 写入对应应用路径（详见 `app/tool/riverpod_codegen/README.md`）。

### 提交与 lint

- **勿提交** `*.g.dart` 与 `lib/src/rust/`（已 gitignore）；只提交 provider 源文件，合并前本地运行 `run_codegen` / `scripts/generate-frb.ps1`
- `analysis_options.yaml` 已排除 `**/*.g.dart`，勿手改生成文件
- `app/pubspec.yaml` 的 `dependency_overrides`（`analyzer` / `dart_style` / `mockito`）为 codegen 工具链所需；升级 Flutter SDK 或 generator 后若 `run_codegen` 失败，先检查这些 override 是否仍适用

### Provider 命名

生成后的全局变量遵循 camelCase + `Provider` 后缀，例如 `LibraryProjects` → `libraryProjectsProvider`，`ProjectWorkspace` family → `projectWorkspaceProvider(projectId)`。

## Metadata 编辑 schema

元数据 Tab **不**在 Flutter 维护字段分段、可见性或表单→`Metadata` 合并规则；这些由 Core `metadata_schema` 模块定义，经 FRB 暴露：

- `getMetadataEditorSchema(exportFormat: …)` — 分段、字段类型、标签、下拉选项、OPF 固定版式只读项
- `metadataFieldDisplayValue(metadata: …, fieldId: …)` — 从 `Metadata` 读取字段展示值
- `mergeMetadataFromForm(…)` — 按 Export 格式将表单值合并为可持久化的 `Metadata`

`MetadataPanel` 只负责按 schema 渲染控件与收集输入。修改 ComicInfo / OPF 编辑字段时，改 `core/src/metadata_schema/mod.rs` 并重新跑 FRB codegen。

## FRB Metadata DTO

- **权威模型**：`core/src/db/metadata.rs` 的 `MetadataRecord`；FRB 暴露为 `api/metadata.rs` 中的 `Metadata`（Dart：`app/lib/src/rust/api/metadata.dart`）。
- **禁止**在 `app/lib/` 为 `Metadata` 手写大段 `copyWith` 镜像；局部改字段走 Core patch API：
  - `metadataWithPageCount`
  - `metadataWithCoverPageIndex`
  - `metadataWithDropdownField`
- 整表保存仍用 `getProjectMetadata` / `updateProjectMetadata`；表单提交用 `mergeMetadataFromForm`。
- `simple.rs` FRB 模块仅 re-export 元数据符号以保持历史 import 路径；新增元数据 API 加在 `metadata` 模块。
- 改 `Metadata` 字段布局时：更新 `MetadataRecord`、FRB `Metadata` 与 `metadata_struct!` 宏，再跑 `scripts/generate-frb.ps1`。

## 反馈模式

### M3 官方反馈规范（摘要）

来源：[Material Design 3 Components](https://m3.material.io/components)。本节为 Agent 速查；细节以官方 Guidelines 为准。

**反馈优先级（打扰程度由高到低）**

| 优先级 | 官方组件 | 典型场景 |
| ------ | -------- | -------- |
| 最高 | [Dialog（Basic）](https://m3.material.io/components/dialogs/guidelines) | 不可逆操作确认、必须阅读后才能继续的 alert |
| 中 | （M2 Banner；**M3 无独立 Banner 组件**） | 需持续可见的警告 → 用 inline 区域消息或 Dialog |
| 最低 | [Snackbar](https://m3.material.io/components/snackbar/guidelines) | 操作已完成、可撤销、轻量过程反馈 |

**组件要点**

| 组件 | 官方定位 | 文档 |
| ---- | -------- | ---- |
| **Snackbar** | 关于应用进程的**简短、临时**消息；不阻断主任务；同一时刻仅一条；可有 **一个 action**；**不要放 icon** | [Overview](https://m3.material.io/components/snackbar/overview) · [Guidelines](https://m3.material.io/components/snackbar/guidelines) |
| **Dialog** | 模态，阻断背后操作，**应少用**；Basic（居中 alert / 确认）与 Full-screen（多步、需键盘的表单任务） | [Overview](https://m3.material.io/components/dialogs/overview) · [Guidelines](https://m3.material.io/components/dialogs/guidelines) |
| **Progress indicators** | 进行中流程的状态（加载、保存）；表达用户是否可离开当前屏 | [Overview](https://m3.material.io/components/progress-indicators/overview) |
| **Badge** | 导航项 / 图标上的计数或状态点 | [Overview](https://m3.material.io/components/badges/overview) |

**Errors 模式**（[Material Errors](https://m1.material.io/patterns/errors.html)，M3 组件层仍沿用）：

- 单字段校验失败 → 字段下方 **inline error**（替换 helper text）
- 多字段不兼容 → 各字段标错 + 表单 / 页面顶部汇总
- **Snackbar** 仅用于 **peripheral、transient** 错误
- **不要用 Snackbar** 表达 critical、persistent、bulk 错误

**官方大屏 Snackbar 位置**：Android Material 实现在大屏设备上为视口 **leading 下角**（LTR 为左下），见 [Snackbar API](https://developer.android.com/reference/com/google/android/material/snackbar/Snackbar)。

### 本项目桌面适配

| 断点 | Snackbar 位置 | 说明 |
| ---- | ------------- | ---- |
| `compact`（&lt; 720px） | **底部居中**（floating，水平 `AppSpacing.md`） | 与窄屏 / 手机一致 |
| `medium+`（≥ 720px，`!isCompact`） | **窗口右下角**（距右 / 下各 `AppSpacing.lg`） | **刻意偏离**官方 leading 左下；相对**窗口**右下角，不扣减 `NavigationRail` 宽度 |

实现：统一经 [`showAppSnackBar`](../../app/lib/ui/core/feedback/app_snack_bar.dart)（[`appSnackBarMarginFor`](../../app/lib/ui/core/feedback/app_snack_bar.dart) 按断点设 `margin`）。**Feature 禁止**直调 `ScaffoldMessenger.showSnackBar`。

### 本项目反馈约定

Feature 内用 **Material 反馈 API** 与 **feature 局部状态组件**；勿在页面中央堆裸 `CircularProgressIndicator` 或自定义错误色条。

| 场景 | 组件 / API | 何时使用 |
| ---- | ---------- | -------- |
| 页面 / Tab 首次加载 | `ProjectEditorPageLoading` 等 feature helper | 等待 FRB 或 workspace 初始化 |
| 整页加载失败 | `ProjectEditorPageErrorState`（`project_editor_page_states.dart`） | 无法继续；提供「重试」等 `action` |
| 可恢复、可继续编辑的错误 | `LibraryInlineErrorBanner` / `ProjectEditorInlineErrorBanner` | 库列表、编辑页 workspace、元数据表单保存失败；可 `onDismiss` |
| 列表 / 面板无数据 | `LibraryEmptyState` / `ProjectEditorEmptyState` | **必须**写 `subtitle` 说明建议下一步 |
| 阻塞长任务 | `runProjectEditorBlockingOperation` 等（`project_editor_dialogs.dart`） | 导出、追加等 |
| 操作结果（非阻塞） | `showAppSnackBar` | 成功提示、可忽略的小失败 |
| 需确认或展示结果摘要 | `showAppOverlayDialog` + `AlertDialog` | 二次确认、导入结果、创建失败详情 |
| 操作失败（需阅读原因） | `showProjectEditorOperationFailure` 等 | **不用 SnackBar**；用 Dialog + `nextStepHint` |

约定：

- **内联错误**用于用户仍留在当前上下文、可重试或关闭提示的场景。
- **SnackBar** 用于不挡内容的轻量反馈；勿替代整页错误或 critical 失败。
- **Dialog** 用于需阅读完整结果或二次确认；长任务进行中用 blocking dialog，不用 Dialog 当无文案 spinner。
- 按钮内 saving 状态可用小号 `CircularProgressIndicator` 或 `FilledButton` 的 `child` 替换。

### 项目编辑页顶栏

- 组件：`ProjectEditorAppBar`（`project_editor_app_bar.dart`）+ `ProjectEditorTabSwitcher`（`project_editor_tab_switcher.dart`）。
- **两行结构**：第一行 AppBar — 返回 + 左「项目名 · N 页」+ 右操作区（导出、追加导入、项目属性）；第二行 — 仅 `SegmentedButton`（图片 / 元数据）。**无** AppBar 底部分割线。
- **项目标题 vs 漫画标题**：顶栏与漫画库列表仅显示 `ProjectSummary.title`（库内项目名 / `project_title`）；**禁止**用 `metadata.title`（导出漫画标题）。元数据保存不得同步项目标题。
- **左信息区**：单行 `项目名 · N 页`（中间点分隔）；0 页时仅显示项目名。用 `EllipsisTooltipText` 整行截断；仅溢出时 hover 显示全文，`waitDuration: 1500ms`。
- **操作按钮**：宽屏导出 `FilledButton`、追加导入 `OutlinedButton`（**40px** 高、M3 桌面标准、宽度随文案）；窄屏导出 / 追加导入 / 项目属性均为圆形 `IconButton` + tooltip。图标均用 Material Icons（header + Tab 行）。
- **桌面 chrome**：窄屏时全宽窗口顶栏仅由 [DesktopShell] 提供；[DesktopStandaloneChrome] 在窄屏不再重复添加（宽屏独立路由仍由其承担）。
- **Tab 行**：宽屏左对齐、内容宽度（不占满）；窄屏全宽 `SegmentedButton`。图标：图片 `Icons.image_outlined`；元数据 `Icons.description_outlined`。
- **重命名**：在项目属性 → 概览 Tab 编辑「项目名称」；调用 `updateProjectTitle`，不影响元数据 `title`。

### 项目标题默认命名（Core）

| 场景 | `project_title` |
| ---- | --------------- |
| 向导填写 | 用户输入 |
| 向导留空 + 图片导入 | `项目A` / `项目B` / …（查库递增字母） |
| 向导留空 + 档案导入 | 档案文件名（去扩展名） |
| 元数据 Tab 改漫画标题 | 不影响项目标题 |

### 元数据 Tab

- 组件：`MetadataPanel`；字段与分段由 Core `getMetadataEditorSchema` 驱动，禁止在 Flutter 硬编码字段表。
- 字段文案：Core schema 提供 `label` + 可选 `hint`；`hint` 保持简短，仅在 `label` 不能表达输入格式时使用。
- **分区（3 Tab）**：`常规`（`general`）→ 漫画标题、发布日期、语言、年龄分级、简介；`系列`（`series`）→ 系列名、期号、总期数；`创作`（`creative`）→ 作者、标签、角色。PDF 与 CBZ/EPUB 共用同一 schema（`editable: true`）。
- **发布日期**：Material `showDatePicker`；只读中文展示（`2024年` / `2024年5月` / `2024年5月31日` / `未设置`）；选日历写入完整 `YYYY-MM-DD`；Import 的 partial 仅展示、不改库直至用户选择或清空；suffix ✕ 清空存 `NULL`。内部仍映射 `published_date_year/month/day` form 字段。
- **年龄分级**：`MetadataAgeRatingField`（`AppDropdownMenu`，`clearable: true`）；选项仅 Core `ageRatingPresets` 四项，不可自由输入；未选占位「未设置」；有值时字段内 suffix ✕ 清空为 `NULL`。Core `age_rating` 模块负责导入/加载别名归一化；`mergeMetadataFromForm` 保存时校验非空值必须在预设内。
- **创作 Tab 逗号标签**：作者 / 标签 / 登场人物共用 `MetadataCommaTagsField`（`InputChip` + `TextField`）；Chip 与输入同区换行；逗号或回车添加（不用空格分隔）；大小写不敏感去重；持久化为逗号分隔且逗号后无空格。Core `mergeMetadataFromForm` 对三字段均 `normalize_comma_separated_tags`。
- 分区切换使用 `SectionChipBar`（`SegmentedButton`）；**不**显示「元数据」标题行，保存中状态显示在分区切换行右侧。
- 未保存：`onDirtyChanged` 同步至编辑页；切换 Tab / 返回漫画库前 `confirmDiscardMetadataEdits`（`metadata_unsaved_guard.dart`）。
- 导入元数据：`ImportMetadataPreview` 为只读归档预览；可编辑区为「导出元数据」表单。
- **页数 / 封面**：不在元数据 Tab 展示或编辑；页数见编辑页顶栏，封面在图片 Tab「设为封面」。schema 不含 `PageCountInfo` / `CoverPageIndex` 字段类型。
- `editable: false` 时仍显示「当前格式不支持编辑」空状态（基础设施保留，当前各格式均为可编辑）。
- 保存成功用 SnackBar；保存失败用表单上方的 `ProjectEditorInlineErrorBanner`。

### 图片 Tab

- 组件：`ProjectEditorImagesTab`（`project_editor_images_tab.dart`）+ `PageThumbnailGrid`（`pages/pages_panel.dart`）；`SliverGrid` 布局，缩略图宽高比 `3:4`，格子直角且无描边（页码/封面角标仍用小圆角），列数由 `pageThumbnailCrossAxisCount` 按可用宽度计算（2–8 列，单格最小约 `96px` 宽），末格为「添加页面」。
- **缩略图解码**：禁止裸 `Image.file` 全分辨率解码；用 `pageThumbnailTileSize` + `pageThumbnailCacheSize` 按单格逻辑尺寸 × `devicePixelRatio` 设置 `cacheWidth` / `cacheHeight`；`FilterQuality.low`、`gaplessPlayback: true`；加载前以 `surfaceContainer` 底色占位。大项目（约 300+ 页）可后续在 Core 引入 page 级缩略图缓存。
- **重建隔离**：`ProjectEditorImagesTab` 经 `ref.watch(…select((s) => (s.pages, s.coverPageIndex)))` 订阅页列表；每格 `RepaintBoundary`；workspace 其他字段（导出格式保存、error 等）变化不得重建整网格。
- 页面操作统一走缩略图 hover / overflow 菜单（`PageThumbnailHoverMenu`）：宽屏 hover 显示圆形 `IconButton(Icons.more_vert)` + **`MenuAnchor`**（与漫画库 `ProjectCard` 同款）；窄屏长按 `showMenu`。菜单项 `MenuItemButton` / `PopupMenuItem` 高度 **48px**、Material 图标、**无分割线**；删除项用 `error` 色。
- **页码 / 封面角标**：Assist Chip 风格 pill（页码 `surfaceContainerHighest`；封面 `primaryContainer` + `Icons.bookmark_outline`），无描边。
- 封面页：`sortIndex == coverPageIndex` 时仅显示「封面」角标（**无**格子描边）。
- 查看原图（`page_image_viewer.dart`）：全屏黑底；点图片外留白关闭（无顶部关闭按钮）；左右圆形半透明翻页按钮（44px、常见 lightbox 样式，首/末页隐藏不可用侧）；`Escape` 关闭，`←` / `→` 翻页；`InteractiveViewer` 仅覆盖图片显示区域。
- 排序调用 FRB `reorderPages`（经 `ProjectWorkspace.reorderPages`）。

### 漫画库导入

- 逻辑集中在 `library_import_flow.dart`；成功 / 失败结果用 `AlertDialog`。
- **不**在导入成功后自动进入编辑页；对话框或 SnackBar 提供「打开项目」。
- 失败时 `LibraryInlineErrorBanner` 可带 `onRetry`（复用上次路径）。

### 新建项目

- 逻辑集中在 `create_project_wizard_flow.dart`；确认创建后关向导，后台执行 `library.createFromDraft`。
- 进度与结果用 `ScaffoldMessenger.showSnackBar`（loading 可关闭，任务继续；成功带「打开项目」；失败常驻并带「查看详情」→ `AlertDialog`）。
- **不**在创建成功后自动进入编辑页。

## Tooltip 约定

默认**不要**在 hover 时显示 tooltip；仅下列场景使用：

**出现延迟**：`AppTheme` 通过 `tooltipTheme.waitDuration` 设为 [`AppDurations.tooltipWait`](../../app/lib/ui/core/theme/app_tokens.dart)（**1 秒**）。未显式传 `waitDuration` 的 `Tooltip` / `IconButton` 继承该值；已有局部 override（如漫画库卡片标题 400ms、`EllipsisTooltipText` 1500ms）**保持不变**。

| 场景 | 做法 |
| ---- | ---- |
| 控件旁已有可见文字标签 | **不要** tooltip（含 `NavigationRail` 展开标签、带宽文字的 `FilledButton`） |
| 纯图标且语义直观 | **不要** tooltip（返回、关闭、排序、⋮ overflow 等） |
| 纯图标且语义不够直观 | `IconButton` 的 `tooltip`（如「项目属性」「清空」、窄屏导出格式说明） |
| 禁用且原因无法从标签读出 | 外包 `Tooltip` 包裹禁用按钮 |
| 文字截断需看全文 | 保留（如 `project_card` 标题 `TextOverflow.ellipsis`、`EllipsisTooltipText`） |

实现要点：

- 图标按钮用 `IconButton`；仅在上述需要时传 `tooltip`。
- 勿为「重复标签文字」的控件加 tooltip。

`MetadataPanel` 的 `TextEditingController` 仅在组件卸载时 dispose；页面重排只通过 `pageCount` 同步页数，勿在每次 `reloadPages` 时强制整表重载。

项目编辑页使用 **图片 / 元数据** 两个 Tab（`TabBar` + `TabBarView`），各自编辑页面与 ComicInfo，不再使用三栏同屏或底部导航切换。

CBZ 默认导出目录存于 `shared_preferences`（`exportPathProvider`）。未配置时导出对话框提供「导出成功后设为默认导出目录」；已配置则直接写入该目录并在对话框中提示完整目标路径。可在设置页更改或清除。

## 测试 support 目录（镜像 `lib/` 分层）

`app/test/support/` 与生产代码分层对应，测试文件按用途 import：

| 路径 | 用途 | 典型消费者 |
| --- | --- | --- |
| `data/repositories/in_memory_core_gateway.dart` | 实现 [`CoreGateway`](../../app/lib/data/repositories/core_gateway.dart) 的内存 fake | `library_operations_test`、`metadata_editing_session_test`、`archive_import_runner_test` |
| `frb/rust_fake.dart` | **`FakeRustLibApi`**（完整 `RustLibApi`）+ **`initRustTestFake`**；re-export `InMemoryCoreGateway` 与 fixture 常量 | Widget / 导航测试（仍经 `RustLib.initMock`） |
| `metadata/metadata_editor_schema.dart`、`metadata_clone.dart` | 元数据 schema / patch 行为（FRB DTO） | 由 `InMemoryCoreGateway` 内部使用 |
| `ui/features/project_editor/metadata_panel_harness.dart` | `pumpMetadataPanel`（`MaterialApp` + `AppTheme.light()`） | `metadata_panel_test` |

**Domain / use case 单测**：直接 `import package:comic_book_maker/domain/use_cases/...`，注入 `InMemoryCoreGateway` 作为 `CoreGateway`（见 `library_operations_test.dart`、`export_workflow_resolver_test.dart`）。

**Widget 测试**：不加载 Rust 动态库；在 `setUp` / `setUpAll` 调用 `initRustTestFake()`。工厂：

- `FakeRustLibApi.emptyLibrary()` — 空库
- `FakeRustLibApi.metadataPanel()` — `p1` + fixture 元数据
- `FakeRustLibApi.editorProject()` — 库内单项目，用于编辑页 Tab 测试

**禁止**在各测试文件内再复制整份 `_MockRustLibApi`；仅需定制时构造 `FakeRustLibApi(InMemoryCoreGateway(...))` 或改 gateway / `metadataByProjectId`。

- 全应用 pump：`ProviderScope` + `ComicBookMakerApp`（见 `test/widget_test.dart`）

新增 FRB API 后：先更新 `FakeRustLibApi`（`test/support/frb/rust_fake.dart`），再改各测试；跑 `flutter test` 确认 mock 编译通过。

验收：`rg shadcn_ui app` 应无匹配（`app/lib`、`app/test`）；`rg design_system app/lib/ui/features` 应无匹配。

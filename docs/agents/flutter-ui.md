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

验收（架构迁移完成后）：`rg 'src/rust' app/lib/ui app/lib/providers` 无匹配。本地/CI 可跑 `scripts/check-frb-ui-isolation.ps1`。

## 组件库

使用 **Material 3** + 自封装 **`design_system`**（`app/lib/ui/core/design_system/`），不再使用 `shadcn_ui`。

- 根应用：`MaterialApp.router` + `go_router`（见 `app/lib/main.dart`、`app/lib/ui/core/router/`）
- 主题：`AppTheme.light()`；间距 / 圆角 / 排版见 `app/lib/ui/core/theme/app_tokens.dart`
- 页面与 feature **禁止** 直接 import 第三方 UI 库；控件通过 `design_system` 暴露：
  - `AppButton`、`AppIconButton`、`AppPopupMenu`、`AppPopupMenuPanel`、`AppTextField`（自绘单行输入）、`AppSelect`、`AppCard`、`AppCheckbox`
  - `AppInlineErrorBanner`、`AppEmptyState`、`AppPageLoading`、`AppPageErrorState`
  - `showAppDialog` / `showAppConfirmDialog` / `showAppAlertDialog`
  - `showAppToast` / `showAppSnackBar`
  - `showAppBottomSheet`、`showAppFeatureDialog`
  - Export / Append 见 `export_archive_dialog.dart`、`append_archive_sheet.dart`；新建项目导入见 `create_project_wizard_dialog.dart`

侧栏在 `app/lib/ui/core/shell/sidebar/` 自封装（`Sidebar`、`SidebarMenuButton`、`SidebarInset` 等）；色板：`AppSidebarTheme`。

布局仍可用 `Scaffold`、`CustomScrollView`、`TabBar` / `TabBarView`。

## 页面顶栏

漫画库、设置等主壳页面共用 `PageHeader`（`ui/core/widgets/page_header.dart`）：

- **高度**：标题行 `minHeight` 与 `AppButtonSize.sm` 对齐（`32px`）；宽屏单行时与无 `actions` 页同高；窄屏折行时允许增高。
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

全站通过 `design_system` 统一页面级反馈；**勿**在 feature 页手写裸 `CircularProgressIndicator` 居中块或自定义错误色条。

| 场景 | 组件 / API | 何时使用 |
| ---- | ---------- | -------- |
| 页面 / Tab 首次加载 | `AppPageLoading` | 等待 FRB 或 workspace 初始化；`compact: true` 用于卡片内小块 |
| 整页加载失败 | `AppPageErrorState` | 无法继续（如元数据拉取失败）；提供「重试」等 `action` |
| 可恢复、可继续编辑的错误 | `AppInlineErrorBanner` | 库列表、编辑页 workspace、元数据表单保存失败；可 `onDismiss` |
| 列表 / 面板无数据 | `AppEmptyState` | **必须**写 `subtitle` 说明建议下一步 |
| 短时后台操作 | `runAppBlockingOperation` | 导出、追加等；见 `app_blocking_loading.dart` |
| 可关闭的后台长任务 | `AppToast` + `AppToastController` | 新建项目等：关对话框后在右下角 Toast 反馈 loading / success / error |
| 操作结果（非阻塞） | `showAppToast` / `showAppSnackBar` | 成功提示、可忽略的失败 |
| 需确认或展示结果摘要 | `showAppDialog` / `showAppConfirmDialog` | 导出成功路径等（见 `app_operation_feedback.dart`） |

约定：

- **内联错误**（`AppInlineErrorBanner`）用于用户仍留在当前上下文、可重试或关闭提示的场景。
- **SnackBar** 用于不挡内容的轻量反馈；勿替代整页错误。
- **Dialog** 用于需阅读完整结果或二次确认；长任务进行中用 blocking loading，不用 Dialog 当 spinner。
- 按钮内 saving 状态仍可用小号 `CircularProgressIndicator`（`AppButton` 已内置）。

历史名称 `InlineErrorBanner` / `EmptyState` 为 `AppInlineErrorBanner` / `AppEmptyState` 的 typedef，新代码优先用 `App*` 前缀并通过 `design_system.dart` import。

### 元数据 Tab

- 组件：`MetadataPanel`；字段与分段由 Core `getMetadataEditorSchema` 驱动，禁止在 Flutter 硬编码字段表。
- 未保存：`onDirtyChanged` 同步至编辑页；切换 Tab / 返回漫画库前 `confirmDiscardMetadataEdits`（`metadata_unsaved_guard.dart`）。
- 导入元数据：`ImportMetadataPreview` 为只读归档预览；可编辑区为「导出元数据」表单。
- **页数 / 封面**：不在元数据 Tab 编辑；页数随页面列表与导入由应用写入，封面在图片 Tab「设为封面」。
- 保存成功用 SnackBar；保存失败用表单上方的 `AppInlineErrorBanner`。

### 图片 Tab

- 组件：`PageThumbnailGrid`（`pages/pages_panel.dart`）。
- 页面操作统一走缩略图右上角 overflow 菜单（`PageThumbnailAction`）：查看原图、替换、设封面、前移/后移、删除。
- 封面页：`sortIndex == coverPageIndex` 时主色描边 +「封面」角标。
- 排序调用 FRB `reorderPages`（经 `ProjectWorkspace.reorderPages`）。

### 漫画库导入

- 逻辑集中在 `library_import_flow.dart`；成功结果用 `showAppLibraryImportOutcome`。
- **不**在导入成功后自动进入编辑页；SnackBar 提供「打开项目」。
- 失败时 `AppInlineErrorBanner` 可带 `onRetry`（复用上次路径）。

### 新建项目

- 逻辑集中在 `create_project_wizard_flow.dart`；确认创建后关向导，后台执行 `library.createFromDraft`。
- 进度与结果用根级 `AppToast`（loading 可关闭，任务继续；成功 6 秒自动消失并带「打开项目」；失败常驻并带「查看详情」→ `showAppOperationFailure`）。
- **不**在创建成功后自动进入编辑页。

## Tooltip 约定

默认**不要**在 hover 时显示 tooltip；仅下列场景使用：

| 场景 | 做法 |
| ---- | ---- |
| 控件旁已有可见文字标签 | **不要** tooltip（含侧栏展开态、带宽文字的 `AppButton`） |
| 纯图标且语义直观 | **不要** tooltip（返回、关闭、排序、⋮ overflow 等） |
| 纯图标且语义不够直观 | `AppIconButton` 的 `tooltip`（如「项目属性」「清空」、窄屏导出格式说明） |
| 禁用且原因无法从标签读出 | `AppIconButton.disabledTooltip`；带标签的 `AppButton` 仅在 `onPressed == null` 时外包 `Tooltip` |
| 文字截断需看全文 | 保留（如 `project_card` 标题 `TextOverflow.ellipsis`） |
| 侧栏折叠态（仅图标） | `SidebarMenuButton`：`tooltip` 预置文案 + `showTooltip: true`（展开态 `showTooltip: false`） |

实现要点：

- 图标按钮统一用 `AppIconButton`；勿在裸 `IconButton` 上传 `tooltip`。
- `RevealMenuIconButton` 默认无 tooltip（⋮ 语义已足够直观）。
- 勿为「重复标签文字」的控件加 tooltip。

## 按钮约定

`AppButton` / `AppIconButton` 基于自绘内核（`app_button_core.dart`），**不使用** M3 `FilledButton` / `OutlinedButton` / `TextButton`；无 Material 水波纹，桌面端提供 hover / pressed 背景与键盘 focus ring。

| 变体 | 视觉 |
| ---- | ---- |
| `primary` | 深灰实心填充 |
| `secondary` | 透明底 + 边框（替代旧 `outline` 与 MD tonal） |
| `ghost` | 透明无底，hover 浅底 |
| `destructive` | 红色实心 |

- 尺寸：`AppButtonSize`（`xs`–`xl`，默认 `md`）+ 可选 `AppButtonMetrics` 局部覆盖。
- 圆角：`AppButtonRadius`（`sm` 4px / `md` 8px 默认 / `lg` / `pill` / `circle`）；全局 `AppRadius.sm` 亦为 4px。
- 纯图标按钮统一 `AppIconButton`，variant 与文字按钮相同。
- `secondary` / `ghost` 静止态背景用 hover 目标色 + `alpha: 0` 插值，避免 `Colors.transparent` 动画中间帧发灰；`secondary` 边框全程固定 `AppColors.outline`。

## 颜色过渡动画（`AnimatedContainer`）

自绘控件的 hover / pressed 背景若用 `AnimatedContainer`（或 `AnimatedDecoration`）做颜色过渡，**禁止**在「无背景」静止态使用 `Colors.transparent`，再在 hover 时切到不透明灰阶色。

### 现象

`Color.lerp(Colors.transparent, surfaceContainer, t)` 会对 RGBA 四维插值；`transparent` 的 RGB 为 `(0,0,0)`，中间帧会先出现**偏深的灰色**，再过渡到目标浅灰，视觉上像闪一下脏色。窄屏底栏 `MobileNavTab`、侧栏 `SidebarMenuButton` 等均可能踩坑。

### 正确做法（二选一）

| 场景 | 静止态 | hover / pressed | 参考 |
| ---- | ------ | --------------- | ---- |
| 静止态需与**父级同色**（看起来「无底」） | 父级实色 token，如 `AppSidebarTheme.menuItemBackgroundRest` → `scheme.surface` | `menuItemBackgroundHover` → `surfaceContainer` | `sidebar_theme.dart`、`mobile_nav_tab.dart` |
| 静止态为**透明按钮**（如 ghost / secondary） | hover 目标色 + **`alpha: 0`**（勿用 `Colors.transparent`） | 同一色相应 `alpha: 1` | `app_button_core.dart` 中 `_alphaBackground` |

要点：

- `someColor.withValues(alpha: 0)` 与 `Colors.transparent` 不同：前者保留 RGB，插值只在透明度与同一色相之间进行。
- 导航项常态应与壳层面板同色（`menuItemBackgroundRest`），代码注释见 `AppSidebarTheme`。
- 新增自绘 hover 背景前，先确认静止态与目标态均为**可安全 lerp 的不透明色**，或采用「同色相 + alpha」方案。

## 弹出菜单

锚点弹出菜单统一 `AppPopupMenu` + `AppPopupMenuPanel`（自绘 overlay），**勿**在 feature 直接使用裸 `PopupMenuButton`。

- `AppPopupMenu`：菜单左缘对齐锚点左缘、默认 `verticalMargin: 0`；遮罩 `Colors.transparent`（点外关闭）；下方空间不足时自动上翻，右溢时水平 clamp；`Escape` 关闭。
- 展开时锚点 `AppIconButton` 经 `AppPopupMenuOpenScope` 保持 hover 打开态。
- `AppPopupMenuPanel`：白底、`outline` 细边框、`md` 圆角、四周 `4px` 内边距、轻阴影（`blur 12` / `offset (0,4)`）；宽度内容自适应。
- `AppPopupMenuItem`：自绘无 ripple；`px 8` / `py 6`、`sm` 圆角；背景拉满行宽（`AppPopupMenuPanel` 内 `IntrinsicWidth` + 父 `Column(crossAxisAlignment: stretch)`，overlay 中勿对项使用 `width: double.infinity`）；项间 `2px` gap（`Column(spacing: AppSpacing.xs / 2)`）；hover `surfaceContainer`；`selected: true` 常驻浅灰底，hover 时 `surfaceContainerHigh`；可选 `leading`（排序方向 icon）。
- 漫画库排序按钮：`LibrarySortMenuButton`，无 tooltip（排序图标语义已足够直观）。

## 表单控件

`AppTextField`、`AppSelect`、`AppCheckbox` 等表单原语共用以下约定（与 shadcn 控件对齐）：

- **控件高度**：单行触发器 / 输入框 `36px`（`AppTypography.controlHeight`）。
- **描边容器**：`AppColors.surface` 底、`AppRadius.md` 圆角、`AppColors.outline` 1px 边框；`AnimatedContainer` 过渡 `150ms`。
- **键盘 focus**：仅 `FocusHighlightMode.traditional` 时显示 `AppColors.primary` 描边；鼠标点击聚焦不显示粗边框（见 `AppSelect` / `AppTextField`）。
- **标签与说明**：`label` 在控件上方、间距 `6px`；`helper` 在下方、间距 `6px`、`onSurfaceVariant` 小字；有 `errorText` 时优先展示错误文案（`AppColors.error`），不显示 `helper`。
- **输入框实现**：`AppTextField` 外壳自绘，内部为无边框 `TextField`；`MetadataPanel` 等 schema 驱动表单仍可用主题 `InputDecorationTheme`，迁移另开任务。

## 对话框

- `AppDialog` / `showAppDialog` / `showAppFeatureDialog`：标题行底部分隔线；底部操作区为 `outline` 分隔线 + 右对齐按钮行（次要左、主要右，间距 `8px`）；`showAppFeatureDialog` 默认 `barrierDismissible: true`（点遮罩等同取消）。
- 侧栏 Tab 功能对话框统一 `SideTabFeatureDialog` + `SideTabDialogShell`（新建项目、项目属性等），经 `showAppFeatureDialog` 限制宽屏最大宽度；限宽在对话框 build 时按当前 `MediaQuery` 断点计算，窗口缩放即时生效。
- 宽屏（≥560px）：`AppDialog` body `contentPadding: 0`；左侧 Tab 贴左贴顶，左 `primary` 指示条（行级）+ 图标文字，hover `surfaceContainer`；Tab 列与内容区 `outline` 竖线拉满 body 高度（与 header/footer 分隔线相交）；右侧内容区保留 `16px` 内边距。
- 窄屏（<560px）：Tab 移至 `AppDialog` 标题行右侧（仅文字 + 底部 `primary` 指示条）；body 零外边距，内容区 `16px` 内边距。

## 常用映射

| 场景           | design_system                                 |
| -------------- | --------------------------------------------- |
| 主操作         | `AppButton` variant `primary`                 |
| 次要 / 线框    | `AppButton` variant `secondary`               |
| 轻量文字操作   | `AppButton` variant `ghost`                   |
| 危险操作       | `AppButton` variant `destructive`             |
| 图标按钮       | `AppIconButton`（同 variant 枚举）            |
| 锚点弹出菜单   | `AppPopupMenu` + `AppPopupMenuPanel`          |
| 对话框         | `showAppDialog` / `showAppConfirmDialog`      |
| 底部 Sheet     | `showAppBottomSheet`                          |
| 卡片           | `AppCard`                                     |
| 内联错误       | `AppInlineErrorBanner`（`errorContainer`）    |
| 空状态 / 加载  | `AppEmptyState` / `AppPageLoading`            |
| 操作反馈       | `showAppToast` → `ScaffoldMessenger` SnackBar |

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

验收：`rg shadcn_ui app` 应无匹配（`app/lib`、`app/test`）。

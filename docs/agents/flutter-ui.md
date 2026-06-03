# Flutter UI 约定

## 组件库

使用 **Material 3** + 自封装 **`design_system`**（`app/lib/ui/design_system/`），不再使用 `shadcn_ui`。

- 根应用：`MaterialApp.router` + `go_router`（见 `app/lib/main.dart`）
- 主题：`AppTheme.light()`；间距 / 圆角 / 排版见 `app/lib/ui/theme/app_tokens.dart`
- 页面与 feature **禁止** 直接 import 第三方 UI 库；控件通过 `design_system` 暴露：
  - `AppButton`、`AppIconButton`、`AppTextField`、`AppCard`、`AppCheckbox`
  - `AppInlineErrorBanner`、`AppEmptyState`、`AppPageLoading`、`AppPageErrorState`
  - `showAppDialog` / `showAppConfirmDialog` / `showAppAlertDialog`
  - `showAppToast` / `showAppSnackBar`
  - `showAppBottomSheet`、`showAppFeatureDialog`
  - Import / Export / Append 见 `import_archive_sheet.dart`、`export_archive_dialog.dart`、`append_archive_sheet.dart`

侧栏在 `app/lib/ui/shell/sidebar/` 自封装（`Sidebar`、`SidebarMenuButton`、`SidebarInset` 等）；色板：`AppSidebarTheme`。

布局仍可用 `Scaffold`、`CustomScrollView`、`TabBar` / `TabBarView`。

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

因 `flutter_test` 与 `riverpod_generator` 的 `analyzer` 约束冲突，**在 app 根目录直接跑 `build_runner` 可能失败**。请使用独立工作区：

```powershell
# Windows
.\app\tool\riverpod_codegen\run_codegen.ps1
```

```bash
# macOS / Linux
./app/tool/riverpod_codegen/run_codegen.sh
```

脚本会同步 `app/lib/providers/` 中的源文件、运行 `build_runner`，并将 `*.g.dart` 拷回 `app/lib/providers/`。

### 提交与 lint

- **提交** provider 源文件与对应的 `*.g.dart`（一并 review）
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

## 常用映射

| 场景           | design_system / M3                          |
| -------------- | --------------------------------------------- |
| 主操作         | `AppButton` / `FilledButton`                  |
| 次要操作       | `AppButton` variant `secondary` / `tonal`     |
| 线框按钮       | `AppButton` variant `outline`                 |
| 危险操作       | `AppButton` variant `destructive`             |
| 图标按钮       | `AppIconButton`                               |
| 对话框         | `showAppDialog` / `showAppConfirmDialog`      |
| 底部 Sheet     | `showAppBottomSheet`                          |
| 卡片           | `AppCard`                                     |
| 内联错误       | `AppInlineErrorBanner`（`errorContainer`）    |
| 空状态 / 加载  | `AppEmptyState` / `AppPageLoading`            |
| 操作反馈       | `showAppToast` → `ScaffoldMessenger` SnackBar |

`MetadataPanel` 的 `TextEditingController` 仅在组件卸载时 dispose；页面重排只通过 `pageCount` 同步页数，勿在每次 `reloadPages` 时强制整表重载。

项目编辑页使用 **图片 / 元数据** 两个 Tab（`TabBar` + `TabBarView`），各自编辑页面与 ComicInfo，不再使用三栏同屏或底部导航切换。

CBZ 默认导出目录存于 `shared_preferences`（`exportPathProvider`）。未配置时导出对话框提供「导出成功后设为默认导出目录」；已配置则直接写入该目录并在对话框中提示完整目标路径。可在设置页更改或清除。

## Widget / FRB 测试 fake

Widget 测试不加载 Rust 动态库，通过 `RustLib.initMock` 注入 fake。全项目共用 **`app/test/support/rust_fake.dart`**：

- **`FakeRustLibApi`** — 实现完整 `RustLibApi`；可变状态：`projects`、`metadataByProjectId`
- **`initRustTestFake([fake])`** — 在 `setUp` / `setUpAll` 中调用
- 工厂：
  - `FakeRustLibApi.emptyLibrary()` — 空库
  - `FakeRustLibApi.metadataPanel()` — `p1` + fixture 元数据
  - `FakeRustLibApi.editorProject()` — 库内单项目，用于编辑页 Tab 测试
- 元数据 schema / patch 行为委托 `test/support/metadata_editor_schema.dart` 与 `metadata_clone.dart`

**禁止**在各测试文件内再复制整份 `_MockRustLibApi`；仅需定制时构造 `FakeRustLibApi(...)` 或改 `metadataByProjectId`。

- `MetadataPanel` pump：`test/support/metadata_panel_harness.dart`（`MaterialApp` + `AppTheme.light()`）
- 全应用 pump：`ProviderScope` + `ComicBookMakerApp`（见 `test/widget_test.dart`）

新增 FRB API 后：先更新 `FakeRustLibApi`，再改各测试；跑 `flutter test` 确认 mock 编译通过。

验收：`rg shadcn_ui app` 应无匹配（`app/lib`、`app/test`）。

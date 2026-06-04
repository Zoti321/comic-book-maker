# Flutter 分层目录与 FRB 边界

`app/lib/` 长期以 `ui/` 平铺 feature 文件、`application/` 承载编排逻辑，与 [Flutter 应用架构指南](https://docs.flutter.dev/app-architecture/guide) 的 UI / Data / Domain 分层不一致；同时大量 Widget 与 Riverpod Provider 直接 `import` FRB 生成代码，导致 UI 与 Core API 强耦合、测试 fake 维护成本高。FRB 官方约定生成物位于 `lib/src/rust/`、Rust 面向 Flutter 的 API 位于 `{rust_root}/src/api/`（见 [FRB Directory structure](https://cjycode.com/flutter_rust_bridge/guides/miscellaneous/directory)），本仓库已采用该路径，不应为「对齐 data 文件夹名」而搬迁生成目录。

本 ADR 与 ADR-0001（Rust Core + Flutter UI）、ADR-0004（`app/` + `core/` monorepo）、ADR-0006（`design_system`）兼容；实施切片见 `.scratch/flutter-architecture/`。

## 决策

### 1. Dart 侧目标目录（迁移终点）

```text
app/lib/
├── main.dart                      # RustLib.init、initLibrary、ProviderScope
├── src/rust/                      # FRB codegen ONLY（dart_output，禁止手改）
├── data/
│   └── repositories/              # CoreGateway（Repository 接缝）
├── domain/
│   └── use_cases/                 # 编排：Library、Metadata 会话、Archive runners 等
├── providers/                     # 跨 feature 全局 Riverpod（coreGateway、exportPath）
├── ui/
│   ├── core/                      # design_system、theme、shell、router、layout、共享 widgets
│   └── features/
│       ├── library/               # 漫画库（Library）
│       ├── create_project/        # 新建项目向导（Create Project）
│       ├── project_editor/        # 项目编辑（图片 Tab / 元数据 Tab）
│       └── settings/              # 设置
├── ui/core/project_settings_update.dart   # 共享：ProjectSettings → FRB update
└── (tests 镜像 import 路径，见 flutter-ui.md)
```

迁移已完成：`lib/ui/` 根目录无 `.dart` 文件；勿再添加 re-export 垫片，共享控件进 `ui/core/`。

### 2. 分层职责（词汇对齐 CONTEXT.md）

| 层 | 目录 | 职责 |
| --- | --- | --- |
| **Service（FRB）** | `lib/src/rust/` | Core 经 FRB 暴露的绑定与 DTO；最低层，无应用状态 |
| **Repository** | `data/repositories/` | `CoreGateway`：封装 FRB，对上层提供 Project / Metadata / Import / Export 等操作；测试用 `InMemoryCoreGateway` |
| **Domain（可选加深）** | `domain/use_cases/` | 跨 Repository 的编排（如 `LibraryOperations`、`MetadataEditingSession`、`archive_*_runner`）；无 Flutter import |
| **ViewModel** | `providers/`（及后续 feature 内 provider） | Riverpod Notifier：UI 状态、命令、失效列表 |
| **View** | `ui/features/*`、`ui/core/*` | Widget、flow、dialog；仅 UI 逻辑 |

**Core**（Rust）仍负责 Library Database、Project Storage、Archive Format 的 Import/Export；Flutter 不复制领域规则。

### 3. FRB 与 Rust API 路径（不搬迁）

| 配置 / 路径 | 值 | 说明 |
| --- | --- | --- |
| `app/flutter_rust_bridge.yaml` → `dart_output` | `lib/src/rust` | FRB 官方默认；禁止改为 `lib/data/...` |
| `rust_root` | `../core/` | monorepo：Rust crate 在仓库 `core/` |
| `rust_input` | `crate::api` | 手写 Flutter 面向 API：`core/src/api/*.rs` |
| 应用代码 import FRB | **仅** `main.dart`、`data/repositories/` 实现、测试 support | UI 与 `lib/providers/` **禁止** `import .../src/rust/` |

新增 FRB 符号时：先扩展 `core/src/api/` 并跑 `scripts/generate-frb.ps1`，再在 `CoreGateway` 上暴露；禁止在 feature Widget 中直接调用 `simple.dart` / `metadata.dart`。

### 4. Provider 放置

| 位置 | Provider | 说明 |
| --- | --- | --- |
| `lib/providers/` | `coreGatewayProvider`、`exportPathProvider` | 跨 Library、Project 编辑、Settings |
| `ui/features/library/providers/` | `libraryOperationsProvider`、`libraryProjectsProvider` | 仅漫画库 feature |
| `ui/features/project_editor/providers/` | `projectWorkspaceProvider`（family）、`ProjectWorkspaceState` | 仅项目编辑 feature |

`riverpod_codegen` 对上述三目录分别联接后运行 `build_runner`（见 `app/tool/riverpod_codegen/README.md`）。新增仅单 feature 使用的 Notifier 时优先放入对应 `ui/features/<feature>/providers/`。

### 5. 守卫与验收

- 合并前：`rg 'src/rust' app/lib/ui app/lib/providers` 应为空（`main` 与 `data/repositories` 除外）。
- 鼓励 CI 或 `analysis_options` 规则固化上述禁令。

## 备选

- **将 `dart_output` 迁至 `lib/data/sources/rust`**：与 FRB 模板不一致，生成物非 Repository 实现，且全量改 import，否决。
- **保留 `lib/application/` 命名**：与 Flutter 官方 `domain` 词汇双轨，否决；迁入 `domain/use_cases/`。
- **一次性大挪所有 `ui/*.dart`**：merge 冲突与回归风险高；否决，采用分 feature 切片。

## 后果

- **正面**：UI 与 Core 解耦；Repository 接缝可测；目录与 Agent 文档、官方架构指南一致。
- **负面**：迁移期存在旧路径垫片；须更新 import 与 `docs/agents/flutter-ui.md`。
- **验收**：`docs/adr/0007-*.md` 存在；flutter-ui.md 引用本 ADR；后续 issue 02–10 按 `.scratch/flutter-architecture/` 落地。

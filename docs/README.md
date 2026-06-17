# 文档索引

## 领域与架构

| 路径 | 用途 |
| --- | --- |
| [`CONTEXT.md`](../CONTEXT.md) | 领域术语表（Project、Library、Import/Export 等） |
| [`adr/`](adr/) | 架构决策记录（ADR），记录「为什么这样选型」 |

当前 ADR 摘要：

| 编号 | 主题 |
| --- | --- |
| 0001 | Rust Core + Flutter UI，经 FRB 通信 |
| 0002 | CBR 导入依赖 unrar |
| 0003 | 全局 Library Database（SQLite） |
| 0004 | Monorepo：`app/` + `core/` |
| 0005 | 不做桌面 Archive 文件关联 |
| 0006 | Material 3，弃用 shadcn；`design_system` 已由 0013 自 feature 层退出 |
| 0007 | Flutter 分层目录与 FRB 边界（已落地） |
| 0008 | CBR Export：`rars`、rar50、往返测试门槛 |
| 0009 | 桌面整窗原生毛玻璃壳层（**已废弃**，由 0010 取代） |
| 0010 | 桌面无边框窗口与实色自绘标题栏 |
| 0011 | CB7/7Z Import + Export（`sevenz-rust2`） |
| 0012 | Canonical 元数据模型与 Archive Format 映射边界 |
| 0013 | Material You 全面迁移，feature 直用 Material 控件 |

## Agent 约定

[`agents/`](agents/) 供 Cursor / Claude 等 agent skill 读取：

| 文件 | 用途 |
| --- | --- |
| [`issue-tracker.md`](agents/issue-tracker.md) | GitHub Issues（`gh` CLI） |
| [`triage-labels.md`](agents/triage-labels.md) | Triage 标签（本仓库未启用） |
| [`domain.md`](agents/domain.md) | 如何消费 CONTEXT 与 ADR |
| [`flutter-ui.md`](agents/flutter-ui.md) | Flutter 目录、Material You、Riverpod、测试 support |

## 第三方

| 路径 | 用途 |
| --- | --- |
| [`third-party/unrar.md`](third-party/unrar.md) | CBR 解压（`unrar-ng`）许可与来源说明 |
| [`third-party/rars.md`](third-party/rars.md) | CBR 导出（`rars`）许可与 Import/Export 分工 |

## 项目进度（2026-06）

以下能力已在代码库中实现：

- MVP：库、项目 CRUD、页操作、CBZ/CBR 导入导出、元数据编辑
- UI/UX：Material You（`ColorScheme.fromSeed`）、`NavigationRail` / `NavigationBar` 导航、SnackBar / AlertDialog 反馈、编辑页 Tab 交互
- 架构：`data/` / `domain/` / `ui/features/` 分层，FRB 隔离
- 编辑增强：导出格式、工作流设置、新建项目向导、项目属性侧边 Tab、元数据自动保存

新工作：在 GitHub Issues 新建 PRD/实现 issue，或将决策写入 ADR。

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
| 0006 | Material 3 `design_system`，弃用 shadcn |
| 0007 | Flutter 分层目录与 FRB 边界（已落地） |
| 0008 | CBR Export：`rars`、rar50、往返测试门槛 |
| 0009 | 桌面整窗原生毛玻璃壳层（**已废弃**，由 0010 取代） |
| 0010 | 桌面无边框窗口与实色自绘标题栏 |

## Agent 约定

[`agents/`](agents/) 供 Cursor / Claude 等 agent skill 读取：

| 文件 | 用途 |
| --- | --- |
| [`issue-tracker.md`](agents/issue-tracker.md) | 本地 issue 跟踪（`.scratch/`，不纳入 git） |
| [`triage-labels.md`](agents/triage-labels.md) | Triage 状态与 Category 词汇 |
| [`domain.md`](agents/domain.md) | 如何消费 CONTEXT 与 ADR |
| [`flutter-ui.md`](agents/flutter-ui.md) | Flutter 目录、design_system、Riverpod、测试 support |

## 第三方

| 路径 | 用途 |
| --- | --- |
| [`third-party/unrar.md`](third-party/unrar.md) | CBR 解压（`unrar-ng`）许可与来源说明 |
| [`third-party/rars.md`](third-party/rars.md) | CBR 导出（`rars`）许可与 Import/Export 分工 |

## 项目进度（2026-06）

以下能力已在代码库中实现，**不以 `.scratch/` 为待办来源**：

- MVP：库、项目 CRUD、页操作、CBZ/CBR 导入导出、元数据编辑
- UI/UX：Material 3、`design_system`、全局反馈模式、编辑页 Tab 交互
- 架构：`data/` / `domain/` / `ui/features/` 分层，FRB 隔离
- 编辑增强：导出格式、工作流设置、新建项目向导、项目属性侧边 Tab、元数据自动保存

新工作：在 `.scratch/<feature>/` 新建 PRD/issue，或将决策写入 ADR；已完成且无需留档的 `.scratch` 目录可本地删除。

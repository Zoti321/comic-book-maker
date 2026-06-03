Category: enhancement
Status: done

# Phase 2.4 — Library 导入路径

## What to build

- 评估并实现：导入成功后是否默认进入 Project 编辑（可 toast + 显式「打开项目」）。
- 大文件导入过程 loading；Library 屏错误可重试。

## Acceptance criteria

- [x] 行为在 PRD/issue comment 中记录产品选择（自动打开 vs 留库）
- [x] 导入失败不丢失 Library 上下文
- [x] 警告仍可见（ComicInfo 等）

## 产品决策（2026-06-03）

- **导入成功后留在漫画库**，不自动 `push` 项目编辑页（便于连续导入、减少打断；对应 PRD 用户故事 28）。
- 成功反馈：`SnackBar` 文案 + **「打开项目」** 操作；用户也可点击项目卡片进入编辑。
- **有 warnings**（如 ComicInfo 解析问题）时仍先 `showAppAlertDialog` 展示完整警告，再显示带「打开项目」的 SnackBar。
- 导入过程使用 `runAppBlockingOperation`（「正在导入 CBZ…」）；失败留在库页，`AppInlineErrorBanner` + **重试**（同一文件路径，无需重新选文件）。

实现：`app/lib/ui/library_import_flow.dart`、`showAppLibraryImportOutcome`（`app_operation_feedback.dart`）。

## Blocked by

`.scratch/ui-ux-overhaul/issues/10-global-feedback-states.md`

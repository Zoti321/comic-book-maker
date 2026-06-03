Category: enhancement
Status: done

# Phase 2.2 — Export / 追加导入流程统一

## What to build

- 统一 Export CBZ/EPUB、Append 的进度、成功、失败反馈模式（design_system loading + snackbar/dialog 策略）。
- 默认导出目录提示与 PRD 一致；减少并行 Toast + 裸 `AlertDialog` 混用。

## Acceptance criteria

- [x] 一次 Export 全程只有一种 blocking loading 模式
- [x] 成功/失败用户均能明确下一步
- [x] 与 `exportPathProvider` 行为不变（仅 UX）

## Blocked by

`.scratch/ui-ux-overhaul/issues/08-editor-appbar-interaction.md`

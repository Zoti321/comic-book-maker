Category: enhancement
Status: done

# Phase 2.6 — 元数据 Tab 交互

## What to build

- 强化分段导航、dirty/未保存提示、保存失败贴近表单。
- 导入元数据预览与可编辑字段关系更清晰。
- **可选**：若维护者确认，Library 画廊化（大封面卡片）在 **单独 follow-up** 中做，不阻塞本 issue。

## Acceptance criteria

- [x] 切换 Tab 或返回时，未保存有确认或明显提示
- [x] 保存成功/失败反馈一致（沿用 Phase 2.3 约定）
- [x] schema 驱动逻辑仍在 Core，Flutter 无硬编码字段表

## 实现备注（2026-06-03）

- 未保存：`MetadataUnsavedBanner`、标题「未保存」标签、元数据 Tab `Badge`；离开 Tab / 返回库时 `confirmDiscardMetadataEdits`。
- 保存成功 SnackBar；保存失败 `AppInlineErrorBanner` 紧贴表单上方。
- 导入预览标明只读，并指向下方「导出元数据」可编辑区。
- Library 画廊化不在本 issue 范围。

## Blocked by

`.scratch/ui-ux-overhaul/issues/12-pages-tab-interaction.md`

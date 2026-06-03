Category: enhancement
Status: done

# Phase 2.5 — 图片 Tab 交互

## What to build

- 统一页面操作入口（替换/删除/设封面/查看原图）。
- 封面页视觉强化；有页时「添加页面」入口明显。
- 若 Core 已暴露 reorder API，补排序 UI；否则在 issue comment 记「仅 UI 入口预留」。

## Acceptance criteria

- [x] 所有页面操作从同一交互模式可达（如统一 overflow menu）
- [x] 封面页与 `coverPageIndex` 一致
- [x] 添加页面在网格非空时仍易发现

## 实现备注（2026-06-03）

- Core 已暴露 `reorderPages`；UI 通过 overflow 菜单 **前移 / 后移** 调用（`ProjectWorkspace.movePageEarlier` / `movePageLater`）。拖拽排序未做，可后续追加。
- 所有操作经 `PageThumbnailAction` + 右上角 `⋮` 菜单；点击缩略图仍可快捷「查看原图」。
- 非空网格：顶栏 **添加页面** 按钮 + 网格末尾「添加页面」占位格。

## Blocked by

`.scratch/ui-ux-overhaul/issues/11-library-import-flow.md`

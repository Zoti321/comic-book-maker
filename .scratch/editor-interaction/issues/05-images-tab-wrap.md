Category: enhancement
Status: done

# 图片 Tab：Wrap 缩略图与页操作

## What to build

重做项目编辑页**图片 Tab** 的 Page 展示与交互：用 **Wrap** 网格渲染有序 Page 缩略图，替代当前侧栏列表 + 大预览区主路径（含 `ReorderableListView`、`HorizontalPageStrip` 等）。

**每个缩略图格子**

- `Stack`：底层为 Page 缩略图
- 叠加**页码**（基于 `sort_index`）
- **Cover** 标记（与 Metadata `cover_page_index` 一致）
- 右上角竖三点菜单：替换 Page Image、删除 Page、设为 Cover（复用现有 Page Operation 回调）

**查看原图**

- 点击缩略图打开全屏或对话框，显示对应 Page Image 原图

**范围外（本切片不做）**

- Wrap 内拖拽排序 Page（后续 issue）

**其他**

- 保留 AppBar 添加 Page Image 入口
- 无 Page 时仍显示 EmptyState 与添加引导
- 窄屏与宽屏均以 Wrap 为主布局

## Acceptance criteria

- [x] 多页 Project 在图片 Tab 以 Wrap 显示缩略图，顺序与 Page 序列一致
- [x] 封面 Page 有可见标记；菜单可替换、删除、设为 Cover，且 Cover 变更持久化
- [x] 点击缩略图可查看原图
- [x] 空 Project 仍可添加第一张 Page Image
- [x] v1 不提供 Wrap 内拖拽重排

## Blocked by

None - can start immediately

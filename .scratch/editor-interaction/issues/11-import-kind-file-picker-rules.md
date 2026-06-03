Category: enhancement
Status: done

# 按导入格式限制资源选择器（画廊追加除外）

## What to build

编辑页中除**图片 Tab 末尾「添加页面」**外，所有通过文件选择器引入 Page Image 或 Archive 的入口，其允许的文件类型必须与 Project 当前的 `inferred_import_kind` 一致。

**按 `inferred_import_kind`**

- `images`：仅 Page Image 扩展名（多选）
- `comic_archive`：CBZ / CBR（与现有追加归档流程一致）
- `epub`：`.epub`
- `pdf`：禁用并说明未实现

**始终仅图片（不受导入格式限制）**

- 图片 Tab 画廊末尾的「添加页面」/ 追加 Page Image：仅 Page Image 扩展名，不开放 Archive Format

**与 10 的关系**

- 用户在属性中修改导入格式并清空后，后续选择器立即遵循新类型

## Acceptance criteria

- [x] `inferred_import_kind == images` 时，编辑页追加/替换（非画廊添加页）仅接受 Page Image
- [x] `comic_archive` / `epub` 时，追加入口仅接受对应 Archive 扩展名
- [x] 图片 Tab 末尾添加页面在任何导入格式下仅选 Page Image
- [x] PDF 推断类型下追加入口不可用并有说明

## Blocked by

- [10-project-properties-side-tabs-import-reset.md](10-project-properties-side-tabs-import-reset.md)

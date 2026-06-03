Category: enhancement
Status: done

# 编辑页按推断类型追加导入数据源

## What to build

在项目编辑页提供「从数据源导入」，向**已有 Project** 追加内容；不改变 `inferred_import_kind`，不删除已有 Page。

**行为按 `inferred_import_kind`**

- `images`：多选 Page Image → 追加到 Page 序列末尾（复用现有添加 Page 流程）
- `comic_archive`：选择 CBZ/CBR → Core 读取档案内 Page Image，**追加到末尾**（新页 `sort_index` 接在现有最大序号之后）
- `epub`：选择 EPUB → 按 spine 顺序追加 Page Image 到末尾
- `pdf`：禁用，说明未实现

**元数据与资源**

- 若追加的档案含 ComicInfo 或 OPF metadata，按 03 规则**更新**导入元数据快照
- 失败时使用与现有 Library Import 相同的回滚策略，避免部分 Page 损坏 Project

**UI**

- 导入入口标签与只读 `inferred_import_kind` 一致
- 完成后刷新 Page 列表与 Cover Thumbnail

## Acceptance criteria

- [x] 已有 3 页的 Project 再导入含 5 页的 CBZ → 共 8 页，顺序为原 3 页之后接新 5 页
- [x] `inferred_import_kind` 在追加导入前后不变
- [x] 各推断类型对应正确的选择器；PDF 不可用
- [x] 导入失败不留下不一致的 Page 或 Asset Reference
- [x] 追加档案含元数据时，元数据 Tab XML 预览更新为最新快照

## Blocked by

- [01-export-format.md](01-export-format.md)
- [03-import-metadata-xml-preview.md](03-import-metadata-xml-preview.md)

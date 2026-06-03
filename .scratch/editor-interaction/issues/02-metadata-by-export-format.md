Category: enhancement
Status: done

# 按 Export 格式驱动元数据编辑

## What to build

元数据 Tab 的**导出元数据编辑**由 Project 的 `export_format` 决定，不再让用户手动切换「编辑模型」。

- `export_format = comic_archive`：展示现有 ComicInfo 分段表单（书目字段完整编辑）
- `export_format = epub`：展示 OPF metadata 编辑 UI（与 EPUB Export 使用的 Dublin Core 及漫画固定版式扩展 meta 一致，例如 rendition、book-type 等导出时会写入的项）
- `export_format = pdf`：无 PDF Export 实现；展示只读说明或禁用编辑区

保存行为不变：编辑结果写入 Library Database；Export CBZ/EPUB 时使用更新后的 Metadata。移除用户对 `MetadataProfile.common` 的入口（内部映射逻辑可保留）。

## Acceptance criteria

- [x] 无手动「编辑模型」下拉；切换 Project `export_format` 后表单集自动切换
- [x] `comic_archive` 路径下可编辑并保存 ComicInfo 对齐字段；Export CBZ 反映变更
- [x] `epub` 路径下可编辑并保存 OPF 对齐字段；Export EPUB 反映变更
- [x] `pdf` 时不提供可保存的导出元数据表单
- [x] 保存失败与校验错误在 UI 可见；术语与 Metadata / Export 一致

## Blocked by

- [01-export-format.md](01-export-format.md)

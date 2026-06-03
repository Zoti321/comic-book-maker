Category: enhancement
Status: done

# Project 导出格式与推断导入类型

## What to build

为 Project 增加可编辑的 **Export 目标格式**（`export_format`）与只读的 **推断导入类型**（`inferred_import_kind`），贯穿 Core 持久化、FRB 与项目编辑页 UI。

**持久化字段**

- `export_format`：`epub` | `comic_archive` | `pdf`（PDF 仅占位，不可执行 Export）
- `inferred_import_kind`：`images` | `comic_archive` | `epub` | `pdf`（PDF 仅占位）

**写入规则**

- Library Import（CBZ/CBR/EPUB）创建 Project：设置 `inferred_import_kind` 与默认 `export_format`（与 Archive Format 对齐；漫画压缩包 → `comic_archive`，EPUB → `epub`）
- Create Project / 仅通过添加 Page Image 建项：默认 `inferred_import_kind = images`，`export_format = comic_archive`（与现有 CBZ Export 主路径一致）
- `inferred_import_kind` 仅在尚未定型时写入（首次 Import 或首次档案导入），之后不变

**项目编辑页**

- 用户可修改 `export_format`（下拉）；`inferred_import_kind` 只读展示
- PDF 在设置与 Export 中可见但禁用，并说明尚未实现

**Export**

- AppBar 单一「Export」入口，按当前 Project 的 `export_format` 调用 CBZ 或 EPUB Export；不再并列两个独立导出菜单项

## Acceptance criteria

- [x] 修改 `export_format` 后写入 Library Database，重进项目编辑页仍生效
- [x] `inferred_import_kind` 在 UI 可见但不可编辑；Library Import 后显示与源 Archive Format 一致
- [x] Create Project 默认 `inferred_import_kind = images`、`export_format = comic_archive`
- [x] PDF 在设置与 Export 中不可执行并有占位说明
- [x] 单一 Export 按 `export_format` 生成 CBZ 或 EPUB；无 Page 时仍被拒绝并提示
- [x] UI 与 Core 使用 CONTEXT.md 术语（Project、Export、Archive Format、Metadata）

## Blocked by

None - can start immediately

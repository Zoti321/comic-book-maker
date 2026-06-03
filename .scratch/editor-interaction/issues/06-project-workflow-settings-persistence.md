Category: enhancement
Status: done

# 项目工作流设置持久化（Core + FRB）

## What to build

在 Library Database 的 Project 上持久化**工作流偏好**（创建时写入，之后可更新），贯穿 Core、FRB 与 Flutter 可读取的 `ProjectSettings`（UI 可在后续 slice 接入）。

**新增字段（项目级）**

- `delete_project_after_export`（bool，默认 `false`）
- `use_default_export_directory`（bool，默认 `true`：沿用应用全局默认导出目录）
- `export_directory`（可空文本：项目专用导出目录；仅当不沿用全局时使用）
- `comic_archive_container`：`zip` | `seven_zip` | `rar`（默认 `zip`；仅当 Export 目标为漫画压缩包时语义生效）
- `use_comic_archive_extension`（bool，默认 `true`：导出扩展名用 `.cbz` / `.cbr` / `.cb7`；为 `false` 时用 `.zip` / `.rar` / `.7z`）

**与现有字段的关系**

- 保留 `export_format`、`inferred_import_kind`；本 slice 不改动其写入规则（Library Import / Create Project 默认值仍按 Archive Format 对齐，见 01-export-format）

**API**

- FRB 扩展 `ProjectSettings` 与 `get_project_settings` / 统一的 `update_project_settings`（或等价批量更新），避免每个字段单独一条 FRB
- Create Project / Library Import 创建路径写入上述默认值

**范围外**

- 本 slice 不要求完成新建向导或属性对话框 UI（可仅 Core + FRB + 单元测试）

## Acceptance criteria

- [x] 新字段经 schema 迁移写入 `projects` 表，旧项目打开后得到文档化默认值
- [x] FRB 可读写全部工作流字段；Core 测试覆盖 round-trip 与非法枚举拒绝
- [x] Create Project 与 Library Import 创建 Project 时持久化合理默认值
- [x] 术语与 CONTEXT.md 一致（Project、Export、Library Database）

## Blocked by

None - can start immediately

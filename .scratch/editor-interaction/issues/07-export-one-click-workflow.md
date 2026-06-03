Category: enhancement
Status: done

# 一键 Export（路径与导出后删除）

## What to build

Export 行为完全由**项目级工作流设置**驱动，不再在每次 Export 时选择路径或勾选「导出后删除」。

**导出路径解析**

- `use_default_export_directory == true`：目标目录为应用全局默认导出目录（现有 `exportPathProvider` / 设置页）
- 否则：使用项目 `export_directory`（须非空且有效；无效时阻塞 Export 并提示用户在项目属性中修正）
- 文件名由项目标题、`export_format`、漫画压缩包容器与 `use_comic_archive_extension` 决定（zip 已实现路径在本 slice 或 08 中至少支持 `.cbz` / `.zip` 二选一逻辑）

**Export 交互**

- 移除（或不再展示）每次 Export 的路径选择、「设为默认导出目录」等与项目设置重复的 UI
- `delete_project_after_export == false`：确认无删除相关步骤后，blocking 导出 + 成功反馈
- `delete_project_after_export == true`：Export 前**一次**强确认（说明将永久删除本地 Page 与 Metadata），确认后导出并执行与现 Core 相同的删除逻辑，返回漫画库

**范围外**

- 7z / rar 容器真实打包（08 占位）
- 新建向导、属性对话框（09 / 10）

## Acceptance criteria

- [x] 项目勾选沿用全局且全局目录已配置时，Export 不再弹出保存路径对话框，文件写入预期目录
- [x] 项目使用专用导出目录时，Export 写入该目录，不修改全局默认目录
- [x] `delete_project_after_export` 为 false 时，Export 流程无「导出后删除」勾选
- [x] `delete_project_after_export` 为 true 时，Export 前有一次不可忽略的删除确认，成功后 Project 从库中移除并回到漫画库
- [x] 无 Page 时 Export 仍被拒绝并提示（行为与现有一致）

## Blocked by

- [06-project-workflow-settings-persistence.md](06-project-workflow-settings-persistence.md)

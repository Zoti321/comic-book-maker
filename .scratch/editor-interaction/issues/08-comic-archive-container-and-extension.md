Category: enhancement
Status: done

# 漫画压缩包容器算法与扩展名策略 UI

## What to build

当 Project 的 `export_format` 为漫画压缩包（`comic_archive`）时，用户可配置**容器算法**与**扩展名风格**，并反映到 Export 文件名（仅 ZIP 容器可真正 Export）。

**容器算法**

- 可选：`zip`（已实现，对应现有 CBZ Export）、`seven_zip`、`rar`
- 未实现项在 UI 中可见但禁用，附「尚未实现」说明

**扩展名策略（`use_comic_archive_extension`）**

| 容器 | 勾选漫画扩展名 | 不勾选 |
|------|----------------|--------|
| ZIP | `.cbz` | `.zip` |
| RAR | `.cbr` | `.rar` |
| 7Z | `.cb7` | `.7z` |

**UI**

- 在 Export 格式为漫画压缩包时提供算法选择（Flutter 侧优先**二级菜单**或等价子项，主项为「漫画压缩包」）
- 提供「使用漫画扩展名」勾选，与上表联动预览最终扩展名
- 本 slice 至少接入**项目属性 · 导出**区域（10 之前可挂在现有项目属性对话框的导出区块）

**Export**

- 仅 `zip` 容器调用现有 Core Export；其它容器不可执行 Export
- 07 的一键 Export 读取本 slice 字段生成文件名

## Acceptance criteria

- [x] 修改容器或扩展名策略后持久化，重进项目仍生效
- [x] ZIP 容器可成功 Export，文件名符合扩展名策略（`.cbz` 或 `.zip`）
- [x] 7z / rar 在 UI 中占位且禁用；尝试 Export 时有明确「尚未实现」反馈
- [x] EPUB / PDF 的 Export 格式下不显示容器算法控件

## Blocked by

- [06-project-workflow-settings-persistence.md](06-project-workflow-settings-persistence.md)

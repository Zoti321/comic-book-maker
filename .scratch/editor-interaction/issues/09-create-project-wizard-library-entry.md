Category: enhancement
Status: done

# 新建项目侧边 Tab 向导与漫画库入口合并

## What to build

用**侧边纵向 Tab** 对话框（参考 Komga「编辑库」布局）取代「无资源直接 Create Project」与独立的「导入漫画」入口。

**漫画库**

- 主入口仅 **「新建项目」**（移除/合并原「导入漫画」按钮与重复 CTA）
- 不包含桌面 Archive **文件关联**或从 OS 唤起导入（见 `docs/adr/0005-decline-desktop-archive-file-association.md`）

**对话框 Tab（新建）**

1. **导入**（必选）：用户选择并导入 Page Image 或 Archive Format（图片多选 / CBZ / CBR / EPUB）；完成后**自动推断** `inferred_import_kind` 并只读展示
2. **导出**：`export_format`；漫画压缩包时的容器算法 + 「使用漫画扩展名」；项目导出路径（沿用全局 / 专用目录）
3. **行为**：`delete_project_after_export`；可选项目名称（默认「未命名」）

**创建流程**

- 取消：不创建 Project
- 确认创建：Core 创建 Project → 执行与 Library Import 等价的导入 → 写入 06 中全部工作流字段 → 刷新漫画库并可进入编辑页

**文档**

- 更新 `CONTEXT.md` 中 **Library** 词条：删除「桌面端文件关联打开 Archive Format」表述，与 ADR 0005 及本应用 Import 入口一致（仅应用内 Import / 新建向导）

## Acceptance criteria

- [x] 漫画库仅有「新建项目」作为主创建路径；无独立「导入漫画」入口
- [x] 未完成导入 Tab 必选资源时无法完成创建（或创建按钮禁用并有说明）
- [x] 创建后 Project 含正确 Page、`inferred_import_kind` 与全部工作流设置
- [x] 侧边 Tab 可在导入 / 导出 / 行为之间切换，字段校验清晰
- [x] `CONTEXT.md` Library 描述不再声称支持桌面文件关联

## Blocked by

- [06-project-workflow-settings-persistence.md](06-project-workflow-settings-persistence.md)
- [08-comic-archive-container-and-extension.md](08-comic-archive-container-and-extension.md)

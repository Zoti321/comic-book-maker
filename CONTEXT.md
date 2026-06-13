# Comic Book Maker

一款跨平台（桌面 + 移动端）电子漫画制作与编辑工具。用户可在统一的项目工作区中管理页面与元数据，并导入/导出 CBZ、CBR、CB7、EPUB、PDF 等格式。

## Language

**Project（项目）**：
用户正在制作或编辑的一本漫画的逻辑工作单元，包含有序页面序列和元数据；持久化于 Library Database，与 Archive Format 解耦，直到 Export。
_Avoid_: Document, Workbook, Comic file

**Library Database（库数据库）**：
应用数据目录下的单一 SQLite 数据库（`library.db`），存储所有 Project 的 Metadata、页序、Asset Reference 及 Library 列表所需索引；不内嵌 Page Image 二进制数据。
_Avoid_: Project database, Global DB, App database

**Project Storage（项目存储）**：
单个 Project 在磁盘上的资源目录，位于应用沙盒内（如 `{app_data}/projects/{project_id}/`），含 `assets/`（Page Image 文件）与 `.cache/`（Cover Thumbnail）；元数据在 Library Database，用户不直接管理此路径。
_Avoid_: Project file, Project folder, Workspace

**Page（页）**：
Project 中有序排列的一个阅读单元，通常对应一张 Page Image。
_Avoid_: Panel, Spread, Image slot

**Page Operation（页面操作）**：
对 Page 的结构变更（增删、排序、替换资源引用），不改变 Page Image 像素本身。
_Avoid_: Image edit, Page edit, Transform

**Page Image（页图）**：
Page 所引用的位图资源；支持 JPEG（`.jpg`/`.jpeg`）、PNG、WebP、GIF、AVIF、BMP。Import 与 Export 均保持原格式，不做转码。
_Avoid_: Image, Asset, Picture

**Asset Reference（资源引用）**：
指向 Project Storage 内 `assets/` 目录中 Page Image 的相对路径；从外部导入时先复制到该目录再写入 Library Database。
_Avoid_: Image URL, File path, Resource link

**Metadata（元数据）**：
描述 Project 的书目信息，存于 Library Database 的 **canonical 模型**（与 ComicInfo / OPF 等档案字段解耦）。应用内编辑、校验与持久化仅使用下列字段；与各 Archive Format 的映射在 **Import / Export 边界**完成，元数据 Tab 不按 Export 格式切换字段表。

可编辑字段（SQLite 持久化）：

- `title`（必填）
- `series`、`number`、`series_count`（TEXT，支持 `1A` 等非整数期号）
- `published_date`（TEXT NULL，**分级 ISO**：`YYYY` / `YYYY-MM` / `YYYY-MM-DD`；UI 以年 / 月 / 日三栏展示，缺省精度留空，不补假默认值）
- `language_iso`、`author`、`tags`、`characters`、`age_rating`、`description`

系统字段（元数据 Tab 只读；不由用户直接键入 canonical 列）：

- `page_count`：不持久化于 `projects` 表；由 Page 序列计算并注入 `MetadataRecord`
- `cover_page_index`：持久化；在图片 Tab 指定 Cover，元数据 Tab 只读展示

`author` 在 canonical 中表示**单一创作人员字符串**（可含逗号分隔的多人）；Import 时从 ComicInfo 多角色或 OPF 多 `dc:creator` **逗号拼接**写入；Export 时按目标格式拆分或映射（见 ADR-0012）。应用内 UI 标签为「作者」，不区分 Writer / Penciller 等 ComicInfo 角色名。

Import **不再**持久化原始 ComicInfo / OPF XML 快照；无法映射进 canonical 的档案字段在 Import 时丢弃。
_Avoid_: Tags, Properties, ComicInfo（作为应用内模型名）

**Cover（封面）**：
Library 与 Export 中代表 Project 的展示用 Page；由 Metadata 的 `cover_page_index` 指定，默认为第一页。
_Avoid_: Thumbnail page, Front page, Poster

**Cover Thumbnail（封面缩略图）**：
Cover 对应 Page Image 的缩小预览，由 Core 生成并缓存在 Project Storage 的 `.cache/` 内；不属于 Page 序列，Export 时不打包。
_Avoid_: Preview, Thumbnail, Icon

**Archive Format（档案格式）**：
CBZ、CBR、CB7、EPUB、PDF 等面向发布的容器格式；通过 Import 转为 Project，或通过 Export 从 Project 生成。CB7 为 7z 容器的漫画扩展名（`.cb7`），与容器扩展名 `.7z` 等价，类比 CBZ 与 `.zip`。不是编辑时的原生形态。
_Avoid_: Comic file, E-book format, Container

**Core（核心层）**：
Rust 实现的领域与持久化层，负责 Project 生命周期、Library Database、Project Storage、Archive Format 的 Import/Export；Flutter 经 FRB 调用，不包含 UI 与平台文件选择。
_Avoid_: Backend, Engine, Rust layer

**Library（项目库）**：
应用内展示全部 Project 列表的首屏；数据来自 Library Database。通过「新建项目」向导在应用内 Import Page Image 或 Archive Format 并初始化 Project 工作流设置；不提供 OS 级 Archive 文件关联。
_Avoid_: Home, Gallery, Collection

**Import（导入）**：
从 Archive Format 读取内容，在 Library Database 中创建新 Project 并填充 Project Storage；不修改源档案。CBR 与 CB7 在 Core 内解压后走与 CBZ 相同的流程。Page Image 按文件路径自然排序确定页序；若源档案含 ComicInfo 且 PageCount 与实际页数不符则警告。各格式的元数据在 Import 边界映射为 canonical 字段写入 Library Database（ComicInfo 多角色 → `author` 拼接、OPF 多 creator → `author` 拼接、PDF 仅 Document Info 最小子集等；详见 ADR-0012）；**不**保存原始 ComicInfo / OPF XML 快照。EPUB 若同时含 ComicInfo 与 OPF，ComicInfo 优先。
_Avoid_: Open, Load, Convert in place

**Create Project（新建项目）**：
在漫画库通过新建项目向导创建 Project：用户须先选择 Import 来源（Page Image 或 Archive Format），配置 Export 工作流偏好，再由 Core 创建 Project、执行 Import 并持久化设置。Export 前须至少有一页。
_Avoid_: New comic, Blank import, Start from scratch

**Export（导出）**：
从 Library Database 与 Project Storage 生成指定 Archive Format 文件；不修改 Project 或 Library Database 中的编辑状态。canonical 元数据在 Export 边界映射为目标格式（ComicInfo `Penciller`、OPF 多 `dc:creator`、PDF Document Info 最小集等；详见 ADR-0012）；`page_count` 始终以当前 Page 序列为准。
_Avoid_: Save as archive, Publish only

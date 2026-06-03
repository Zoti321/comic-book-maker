# 全局单库 SQLite，项目元数据与页序集中存储

所有 Project 的 Metadata、页序、Asset Reference 存于应用数据目录下的单一 `library.db`；不再为每个 Project File 文件夹维护独立的 `project.db`。备选方案是每项目一个自包含文件夹（含 SQLite + assets），便于整包拷贝，但会导致 Library 索引与 Project 数据双库同步。选定全局单库后，Project 是库中的逻辑实体；磁盘上仅保留各项目的 `assets/` 与 `.cache/` 目录。Project Bundle（`.cbm`）从 v1 日常编辑路径中移除，分享/备份改走 Export CBZ 或后续「导出项目快照」能力。

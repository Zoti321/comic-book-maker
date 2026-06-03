# Rust 核心层 + Flutter UI，经 FRB 通信

领域逻辑、Project File 持久化（SQLite + assets）、以及 CBZ/CBR Import/Export 全部放在 Rust Core 中；Flutter 只负责 UI、平台文件选择与 FRB 调用。备选方案是在 Dart 侧用 drift/sqflite 管 SQLite、Rust 只做格式解析，但那样 IO 与一致性逻辑会分裂在两门语言里，跨平台测试也更难。选定 Rust 为核心后，FRB 暴露粗粒度领域 API（如 `openProject`、`importArchive`），而不是逐条 SQL。

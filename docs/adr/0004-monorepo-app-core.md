# Monorepo：`app/`（Flutter）+ `core/`（Rust）

Flutter 应用与 Rust 核心库并列于仓库根目录：`app/` 负责 UI 与平台文件选择，`core/` 负责 Library Database、Project Storage、Import/Export 等领域逻辑，经 flutter_rust_bridge 通信。备选方案是将 Rust 嵌在 `app/rust/` 下（边界模糊），或 v1 即拆多 crate workspace（过早）。v1 保持单一 `core` crate；若 EPUB/PDF 等格式解析显著膨胀，再拆出 `formats` crate。

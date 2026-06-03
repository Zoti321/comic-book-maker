# 内置 UnRAR 解压库，全平台 Import CBR

v1 需在桌面与移动端 Import CBR（RAR 压缩的漫画档案）。选定在 Rust Core 内嵌 UnRAR 解压能力（如 unrar-rs 等绑定），全平台统一走同一 Import 路径：解压 → 自然排序 → 复制 Page Image 到 Project File 的 `assets/`。仅需解压、不需创建 RAR；Export v1 仍只生成 CBZ，避免 RAR 压缩侧的许可与专利限制。备选方案是桌面内置、移动端不支持 CBR，或依赖系统 `unar`/`7z` CLI，但会导致平台能力不一致或用户环境强依赖。采用内置库后须审阅 UnRAR 许可条款，确认静态链接与 App Store 分发合规。

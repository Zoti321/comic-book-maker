# 在 app/ 目录下重新生成 FRB 绑定（Dart + Rust glue）
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
Set-Location (Join-Path $root "app")
flutter_rust_bridge_codegen generate
Write-Host "FRB codegen complete."

Set-Location (Join-Path $root "app\tool\frb_freezed_codegen")
& (Join-Path $root "app\tool\frb_freezed_codegen\run_codegen.ps1")
Write-Host "FRB freezed codegen complete."

# Windows 上 flutter test / flutter run 默认从 core/target/release/ 加载动态库；
# 结构体线格式变更后必须同步重编，否则 Dart 解码器与旧 native 不匹配。
Set-Location (Join-Path $root "core")
cargo build --release
Write-Host "Core release library rebuild complete."

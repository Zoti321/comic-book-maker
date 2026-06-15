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

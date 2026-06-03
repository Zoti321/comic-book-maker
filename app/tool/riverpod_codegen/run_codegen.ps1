# 将 app/lib/providers 同步到 codegen 工作区并运行 build_runner，再把 .g.dart 拷回。
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppProviders = Join-Path $Root "..\..\lib\providers"
$CodegenProviders = Join-Path $Root "lib\providers"
$CodegenLib = Join-Path $Root "lib"

New-Item -ItemType Directory -Force -Path $CodegenProviders | Out-Null
Copy-Item (Join-Path $AppProviders "library_provider.dart") $CodegenProviders -Force
Copy-Item (Join-Path $AppProviders "export_path_provider.dart") $CodegenProviders -Force
Copy-Item (Join-Path $AppProviders "project_workspace_provider.dart") $CodegenProviders -Force
Copy-Item (Join-Path $AppProviders "project_workspace_state.dart") $CodegenProviders -Force

Push-Location $Root
try {
  dart pub get
  dart run build_runner build --delete-conflicting-outputs
  Copy-Item (Join-Path $CodegenProviders "*.g.dart") $AppProviders -Force
  Write-Host "Generated files copied to $AppProviders"
} finally {
  Pop-Location
}

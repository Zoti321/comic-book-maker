# 创建 rust_builder/rust -> ../../core 目录联接（Windows 构建 cargokit 需要）
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$junction = Join-Path $root "app\rust_builder\rust"
$target = Join-Path $root "core"
if (Test-Path $junction) {
    $item = Get-Item $junction -Force
    if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
        Write-Host "Junction already exists: $junction"
        exit 0
    }
    throw "Path exists and is not a junction: $junction"
}
New-Item -ItemType Junction -Path $junction -Target $target | Out-Null
Write-Host "Created junction: $junction -> $target"

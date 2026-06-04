# 在独立工作区运行 riverpod_generator；providers 通过目录联接指向 app/lib/providers（单一源）。
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppProviders = (Resolve-Path (Join-Path $Root "..\..\lib\providers")).Path
$CodegenProviders = Join-Path $Root "lib\providers"

function Remove-ProvidersLinkOrDirectory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }
  $item = Get-Item -LiteralPath $Path -Force
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    cmd /c rmdir "$Path" 2>$null
    if (Test-Path -LiteralPath $Path) {
      Remove-Item -LiteralPath $Path -Force
    }
  } else {
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
}

# 迁移：删除历史上复制到 codegen 工作区的实体目录，避免与 app 源文件分叉。
Remove-ProvidersLinkOrDirectory -Path $CodegenProviders
New-Item -ItemType Junction -Path $CodegenProviders -Target $AppProviders | Out-Null

Push-Location $Root
try {
  dart pub get
  dart run build_runner build --delete-conflicting-outputs
  Write-Host "Generated *.g.dart written to $AppProviders (via junction)"
} finally {
  Pop-Location
}

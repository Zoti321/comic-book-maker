# 在独立工作区运行 riverpod_generator；通过目录联接指向 app 内各 provider 源目录（单一源）。
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppLib = (Resolve-Path (Join-Path $Root "..\..\lib")).Path
$CodegenLib = Join-Path $Root "lib"

$ProviderRoots = @(
  @{ LinkName = "global_providers"; Target = Join-Path $AppLib "providers" },
  @{
    LinkName = "library_feature_providers"
    Target = Join-Path $AppLib "ui\features\library\providers"
  },
  @{
    LinkName = "project_editor_feature_providers"
    Target = Join-Path $AppLib "ui\features\project_editor\providers"
  }
)

function Remove-LinkOrDirectory {
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

# 迁移：删除历史上复制到 codegen 工作区的实体目录或旧单一路径联接。
if (Test-Path -LiteralPath $CodegenLib) {
  Get-ChildItem -LiteralPath $CodegenLib -Force | ForEach-Object {
    Remove-LinkOrDirectory -Path $_.FullName
  }
} else {
  New-Item -ItemType Directory -Path $CodegenLib | Out-Null
}

foreach ($entry in $ProviderRoots) {
  $linkPath = Join-Path $CodegenLib $entry.LinkName
  Remove-LinkOrDirectory -Path $linkPath
  New-Item -ItemType Junction -Path $linkPath -Target $entry.Target | Out-Null
}

Push-Location $Root
try {
  dart pub get
  dart run build_runner build --delete-conflicting-outputs
  Write-Host "Generated *.g.dart written under app provider source dirs (via junctions)"
} finally {
  Pop-Location
}

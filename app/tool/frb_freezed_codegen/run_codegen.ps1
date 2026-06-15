# 在独立工作区为 FRB 生成的 @freezed 类型运行 freezed；通过目录联接指向 app/lib/src/rust。
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppRust = (Resolve-Path (Join-Path $Root "..\..\lib\src\rust")).Path
$CodegenLib = Join-Path $Root "lib"
$Link = Join-Path $CodegenLib "rust"

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

if (-not (Test-Path -LiteralPath $CodegenLib)) {
  New-Item -ItemType Directory -Path $CodegenLib | Out-Null
}
Remove-LinkOrDirectory -Path $Link
New-Item -ItemType Junction -Path $Link -Target $AppRust | Out-Null

Push-Location $Root
try {
  dart pub get
  dart run build_runner build --delete-conflicting-outputs
  Remove-LinkOrDirectory -Path $Link
  Write-Host "Generated *.freezed.dart under app/lib/src/rust (via junction)"
} finally {
  Pop-Location
}

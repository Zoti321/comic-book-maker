#Requires -Version 5.1
<#
.SYNOPSIS
  Seed Library Profile benchmark data (default 50 projects with Cover Thumbnail).

.DESCRIPTION
  Wraps `flutter test test/tool/seed_library_benchmark_cli_test.dart`.
  Core FRB requires the Flutter engine; plain `dart run` is not supported.

.EXAMPLE
  .\scripts\seed-library-benchmark.ps1

.EXAMPLE
  .\scripts\seed-library-benchmark.ps1 -Count 50 -AppDataDir C:\temp\cbm-bench -Clean
#>
param(
  [int] $Count = 50,
  [string] $AppDataDir = "",
  [switch] $Clean,
  [string] $TitlePrefix = "",
  [switch] $Help
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot "app"

if ($Help) {
  Write-Host @"
Comic Book Maker - Library Profile benchmark seed

Usage:
  .\scripts\seed-library-benchmark.ps1 [-Count <n>] [-AppDataDir <path>] [-Clean]

See docs/agents/library-profile-benchmark.md
"@
  exit 0
}

Push-Location $appDir
try {
  $defines = @(
    "SEED_COUNT=$Count"
  )
  if ($TitlePrefix -ne "") {
    $defines += "SEED_TITLE_PREFIX=$TitlePrefix"
  }
  if ($AppDataDir -ne "") {
    $defines += "SEED_APP_DATA_DIR=$AppDataDir"
  }
  if ($Clean) {
    $defines += "SEED_CLEAN=true"
  }

  $dartDefineArgs = foreach ($define in $defines) {
    @("--dart-define=$define")
  }

  flutter test test/tool/seed_library_benchmark_cli_test.dart @dartDefineArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $resolvedDir = if ($AppDataDir -ne "") { $AppDataDir } else {
    Join-Path $env:TEMP "cbm-library-profile-bench"
  }

  Write-Host ""
  Write-Host "Profile run:"
  Write-Host "  cd app"
  Write-Host "  flutter run --profile -d windows --dart-define=CBM_APP_DATA_DIR=$resolvedDir"
  Write-Host "See docs/agents/library-profile-benchmark.md"
} finally {
  Pop-Location
}

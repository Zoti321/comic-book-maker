# Fail if lib/ui or lib/providers import FRB directly (ADR-0007 / issue 05).
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$appLib = Join-Path $repoRoot 'app\lib'
$pattern = 'src/rust'
$dirs = @(
    (Join-Path $appLib 'ui'),
    (Join-Path $appLib 'providers')
)
$hits = [System.Collections.Generic.List[string]]::new()
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { continue }
    Get-ChildItem -Path $dir -Recurse -Filter '*.dart' | ForEach-Object {
        $file = $_
        Select-String -Path $file.FullName -Pattern $pattern -SimpleMatch | ForEach-Object {
            $rel = $file.FullName.Substring($appLib.Length + 1)
            $hits.Add("${rel}:$($_.LineNumber):$($_.Line.Trim())")
        }
    }
}
if ($hits.Count -gt 0) {
    throw @"
FRB isolation violated: app/lib/ui and app/lib/providers must not import src/rust.
Use package:comic_book_maker/data/repositories/core_gateway.dart instead.

$($hits -join [Environment]::NewLine)
"@
}
Write-Host 'FRB UI/provider isolation OK'

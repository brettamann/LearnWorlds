# Sync repo-root `data/` and `content/` into `app/assets/` so the Flutter
# bundle can reference them without `..` paths (which break Flutter web's
# URL normalization at runtime). Re-run whenever data or content changes.
#
# Usage (from the app/ directory):
#   .\scripts\sync-assets.ps1

$ErrorActionPreference = 'Stop'

$appRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $appRoot
$assetsRoot = Join-Path $appRoot 'assets'

if (-not (Test-Path $assetsRoot)) {
    New-Item -ItemType Directory -Path $assetsRoot | Out-Null
}

function Sync-Dir {
    param([string]$Name)
    $src = Join-Path $repoRoot $Name
    $dst = Join-Path $assetsRoot $Name
    if (-not (Test-Path $src)) {
        Write-Host "Skip: $src not found"
        return
    }
    if (Test-Path $dst) {
        Remove-Item -Recurse -Force $dst
    }
    Copy-Item -Recurse -Path $src -Destination $dst
    Write-Host "Synced $Name -> assets\$Name"
}

Sync-Dir -Name 'data'
Sync-Dir -Name 'content'

Write-Host "Done. Run 'flutter pub get' if you've added new files."

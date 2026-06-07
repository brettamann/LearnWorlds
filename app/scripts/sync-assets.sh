#!/usr/bin/env bash
# Sync repo-root data/ and content/ into app/assets/ for the Flutter bundle.
# See sync-assets.ps1 header for the why.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_root="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$app_root/.." && pwd)"
assets_root="$app_root/assets"

mkdir -p "$assets_root"

sync_dir() {
  local name="$1"
  local src="$repo_root/$name"
  local dst="$assets_root/$name"
  if [ ! -d "$src" ]; then
    echo "Skip: $src not found"
    return
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "Synced $name -> assets/$name"
}

sync_dir data
sync_dir content

echo "Done. Run 'flutter pub get' if you've added new files."

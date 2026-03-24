#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ICONSET_DIR="$ROOT_DIR/Resources/AppIcon.iconset"
ICON_FILE="$ROOT_DIR/Resources/AppIcon.icns"
MODULE_CACHE_DIR="$ROOT_DIR/.build/swiftpm-modulecache"
CLANG_CACHE_DIR="$ROOT_DIR/.build/clang-modules"
XDG_CACHE_DIR="$ROOT_DIR/.build/swift-cache"
TMP_DIR="$ROOT_DIR/.build/app-icon-tmp"
MASTER_ICONSET_DIR="$TMP_DIR/master.iconset"
MASTER_PNG="$MASTER_ICONSET_DIR/icon_512x512@2x.png"
TIFF_DIR="$TMP_DIR/tiff"
MASTER_TIFF="$TMP_DIR/AppIcon.tiff"

rm -rf "$ICONSET_DIR" "$TMP_DIR"
mkdir -p "$ICONSET_DIR" "$MASTER_ICONSET_DIR" "$TIFF_DIR"
mkdir -p "$MODULE_CACHE_DIR" "$CLANG_CACHE_DIR" "$XDG_CACHE_DIR"

CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" \
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
XDG_CACHE_HOME="$XDG_CACHE_DIR" \
swift "$ROOT_DIR/scripts/generate-icon.swift" "$MASTER_ICONSET_DIR"

if [[ ! -f "$MASTER_PNG" ]]; then
  echo "Master PNG not found at $MASTER_PNG" >&2
  exit 1
fi

for spec in \
  "16 icon_16x16.png" \
  "32 icon_16x16@2x.png" \
  "32 icon_32x32.png" \
  "64 icon_32x32@2x.png" \
  "128 icon_128x128.png" \
  "256 icon_128x128@2x.png" \
  "256 icon_256x256.png" \
  "512 icon_256x256@2x.png" \
  "512 icon_512x512.png" \
  "1024 icon_512x512@2x.png"; do
  size=${spec%% *}
  name=${spec#* }
  sips -z "$size" "$size" "$MASTER_PNG" --out "$ICONSET_DIR/$name" >/dev/null
  sips -s format tiff "$ICONSET_DIR/$name" --out "$TIFF_DIR/${name%.png}.tiff" >/dev/null
done

tiffutil -cat \
  "$TIFF_DIR/icon_16x16.tiff" \
  "$TIFF_DIR/icon_32x32.tiff" \
  "$TIFF_DIR/icon_128x128.tiff" \
  "$TIFF_DIR/icon_256x256.tiff" \
  "$TIFF_DIR/icon_512x512.tiff" \
  "$TIFF_DIR/icon_512x512@2x.tiff" \
  -out "$MASTER_TIFF" >/dev/null 2>/dev/null

tiff2icns "$MASTER_TIFF" "$ICON_FILE" >/dev/null

echo "Generated app icon:"
echo "$ICON_FILE"

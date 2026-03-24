#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="$ROOT_DIR/.build/typelingo"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="TypeLingo"
APP_DIR="$DIST_DIR/$APP_NAME.app"
EXECUTABLE_NAME="TypeLingo"
SWIFT_PRODUCT="typelingo"
MODULE_CACHE_DIR="$ROOT_DIR/.build/swiftpm-modulecache"
CLANG_CACHE_DIR="$ROOT_DIR/.build/clang-modules"
XDG_CACHE_DIR="$ROOT_DIR/.build/swift-cache"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
APP_VERSION="${APP_VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUNDLE_ID="${BUNDLE_ID:-io.github.derooce.typelingo}"

mkdir -p "$DIST_DIR" "$MODULE_CACHE_DIR" "$CLANG_CACHE_DIR" "$XDG_CACHE_DIR"

if [[ -x "$ROOT_DIR/scripts/generate-icon.sh" ]]; then
  "$ROOT_DIR/scripts/generate-icon.sh" >/dev/null
fi

echo "Building $SWIFT_PRODUCT..."
CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" \
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
XDG_CACHE_HOME="$XDG_CACHE_DIR" \
swift build \
  --configuration release \
  --scratch-path "$BUILD_DIR" \
  --product "$SWIFT_PRODUCT"

EXECUTABLE_PATH=$(find "$BUILD_DIR" -type f -path "*/release/$SWIFT_PRODUCT" | head -n 1)
if [[ -z "${EXECUTABLE_PATH:-}" || ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Expected executable not found under $BUILD_DIR" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_DIR/Contents/Info.plist"

if [[ -d "$ROOT_DIR/Resources" ]]; then
  find "$ROOT_DIR/Resources" -mindepth 1 -maxdepth 1 ! -name "Info.plist" -exec cp -R {} "$APP_DIR/Contents/Resources/" \;
fi

if command -v codesign >/dev/null 2>&1; then
  if [[ -z "$SIGNING_IDENTITY" ]]; then
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
  else
  codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_DIR" >/dev/null
  fi
  codesign --verify --deep --strict "$APP_DIR"
fi

echo "App bundle created:"
echo "$APP_DIR"

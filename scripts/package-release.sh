#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="TypeLingo"
APP_DIR="$DIST_DIR/$APP_NAME.app"
INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
VERSION="${APP_VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
DMG_BASENAME="TypeLingo-${VERSION}"
ZIP_PATH="$DIST_DIR/${DMG_BASENAME}.zip"
DMG_PATH="$DIST_DIR/${DMG_BASENAME}.dmg"
TMP_DIR="$DIST_DIR/.release-tmp"
DMG_ROOT="$TMP_DIR/dmg-root"
NOTARY_ZIP="$TMP_DIR/${DMG_BASENAME}-notary.zip"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR" "$DMG_ROOT"

APP_VERSION="$VERSION" \
BUILD_NUMBER="$BUILD_NUMBER" \
SIGNING_IDENTITY="$SIGNING_IDENTITY" \
"$ROOT_DIR/scripts/package-app.sh"

if [[ ! -d "$APP_DIR" ]]; then
  echo "App bundle not found at $APP_DIR" >&2
  exit 1
fi

if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
  if [[ -z "$SIGNING_IDENTITY" ]]; then
    echo "NOTARY_KEYCHAIN_PROFILE requires SIGNING_IDENTITY to be set to a Developer ID Application certificate." >&2
    exit 1
  fi

  ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple -v "$APP_DIR"
fi

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH" >/dev/null
fi

if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple -v "$DMG_PATH"
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --verify --deep --strict "$APP_DIR"
  codesign --verify --strict "$DMG_PATH"
fi

echo "Release artifacts created:"
echo "$ZIP_PATH"
echo "$DMG_PATH"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo ""
  echo "Note: These artifacts are ad-hoc signed for local use only."
  echo "They are suitable for your own machine or limited internal testing, but Gatekeeper will still reject them on other Macs."
  echo "For public distribution, rebuild with SIGNING_IDENTITY='Developer ID Application: ...' and notarization."
fi

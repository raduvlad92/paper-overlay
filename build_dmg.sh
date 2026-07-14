#!/usr/bin/env bash
# Builds Paper Overlay as an ad-hoc-signed .app bundle and packages it
# into a distributable .dmg. Requires only Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="PaperOverlay"
VOL_NAME="Paper Overlay"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Packaging/Info.plist)"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

# `swift build --arch a --arch b` needs Xcode's xcbuild, so with Command
# Line Tools only we build each slice via --triple and lipo them together.
echo "==> Building release binaries (arm64 + x86_64)"
swift build -c release --triple arm64-apple-macosx13.0
swift build -c release --triple x86_64-apple-macosx13.0
ARM_BIN="$(swift build -c release --triple arm64-apple-macosx13.0 --show-bin-path)"
X86_BIN="$(swift build -c release --triple x86_64-apple-macosx13.0 --show-bin-path)"
BIN_PATH="$ARM_BIN"

echo "==> Assembling $APP_BUNDLE"
rm -rf "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

lipo -create \
    "$ARM_BIN/$APP_NAME" "$X86_BIN/$APP_NAME" \
    -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Packaging/Info.plist "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

# SwiftPM resource bundle (localized strings); Bundle.module finds it in
# Contents/Resources at runtime.
if [ -d "$BIN_PATH/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -R "$BIN_PATH/${APP_NAME}_${APP_NAME}.bundle" "$APP_BUNDLE/Contents/Resources/"
fi

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "==> Creating $DMG_PATH"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "==> Done: $DMG_PATH"
echo "    Note: the app is unsigned (ad-hoc). First launch: right-click the app -> Open."

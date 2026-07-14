# Shared by build_dmg.sh and build_pkg.sh (source this from the repo root).
# Builds the universal release binary and assembles dist/PaperOverlay.app,
# ad-hoc signed. Defines: APP_NAME, VERSION, DIST_DIR, APP_BUNDLE.

APP_NAME="PaperOverlay"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Packaging/Info.plist)"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# `swift build --arch a --arch b` needs Xcode's xcbuild, so with Command
# Line Tools only we build each slice via --triple and lipo them together.
echo "==> Building release binaries (arm64 + x86_64)"
swift build -c release --triple arm64-apple-macosx13.0
swift build -c release --triple x86_64-apple-macosx13.0
ARM_BIN="$(swift build -c release --triple arm64-apple-macosx13.0 --show-bin-path)"
X86_BIN="$(swift build -c release --triple x86_64-apple-macosx13.0 --show-bin-path)"

echo "==> Assembling $APP_BUNDLE"
# Only replace the app bundle; dist/ may hold other artifacts (pkg/dmg).
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

lipo -create \
    "$ARM_BIN/$APP_NAME" "$X86_BIN/$APP_NAME" \
    -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Packaging/Info.plist "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"
cp Packaging/AppIcon.icns "$APP_BUNDLE/Contents/Resources/"

# SwiftPM resource bundle (localized strings); Bundle.module finds it in
# Contents/Resources at runtime.
if [ -d "$ARM_BIN/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -R "$ARM_BIN/${APP_NAME}_${APP_NAME}.bundle" "$APP_BUNDLE/Contents/Resources/"
fi

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

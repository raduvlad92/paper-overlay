#!/usr/bin/env bash
# Builds Paper Overlay as an ad-hoc-signed .app bundle and packages it into
# a .dmg. NOTE: the guided .pkg installer (build_pkg.sh) is the recommended
# distribution artifact — apps dragged out of a downloaded dmg stay
# quarantined and get hard-blocked by Gatekeeper on macOS 15+.
# Requires only Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

source Packaging/assemble_app.sh

VOL_NAME="Paper Overlay"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

echo "==> Creating $DMG_PATH"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
cp "Packaging/If the app won't open - READ ME.txt" "$STAGING_DIR/"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "==> Done: $DMG_PATH"
echo "    Note: the app is unsigned. On macOS 15+ a downloaded copy is blocked"
echo "    on first open: Done -> System Settings -> Privacy & Security -> Open Anyway."

#!/usr/bin/env bash
# Builds the guided .pkg installer (Installer.app wizard with welcome and
# conclusion pages). Unlike a dmg drag-install, files installed by a .pkg
# never receive the quarantine attribute, so the installed app launches
# without any Gatekeeper dialog. Requires only Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

source Packaging/assemble_app.sh

PKG_ID="com.raduvlad.PaperOverlay"
COMPONENT_PKG="$DIST_DIR/PaperOverlay-component.pkg"
INSTALLER_PKG="$DIST_DIR/$APP_NAME-$VERSION-Installer.pkg"

echo "==> Building component package"
pkgbuild \
    --component "$APP_BUNDLE" \
    --install-location /Applications \
    --scripts Packaging/pkg/scripts \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    "$COMPONENT_PKG" >/dev/null

echo "==> Building installer wizard package"
DIST_XML="$DIST_DIR/distribution.xml"
sed "s/VERSION_PLACEHOLDER/$VERSION/" Packaging/pkg/distribution.xml > "$DIST_XML"
productbuild \
    --distribution "$DIST_XML" \
    --resources Packaging/pkg/resources \
    --package-path "$DIST_DIR" \
    "$INSTALLER_PKG" >/dev/null
rm -f "$COMPONENT_PKG" "$DIST_XML"

echo "==> Done: $INSTALLER_PKG"
echo "    Downloaded copies are blocked once by Gatekeeper (unsigned):"
echo "    double-click -> Done -> System Settings -> Privacy & Security -> Open Anyway."
echo "    The wizard then installs the app quarantine-free: no further warnings."

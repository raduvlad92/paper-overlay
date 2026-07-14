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
# Stage the payload and disable Installer's bundle relocation: with the
# default (relocatable), Installer follows Spotlight to any existing copy
# of the bundle ID and installs THERE instead of /Applications.
PKG_ROOT="$DIST_DIR/pkgroot"
COMPONENT_PLIST="$DIST_DIR/component.plist"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT"
cp -R "$APP_BUNDLE" "$PKG_ROOT/"
pkgbuild --analyze --root "$PKG_ROOT" "$COMPONENT_PLIST" >/dev/null
/usr/libexec/PlistBuddy -c 'Set :0:BundleIsRelocatable false' "$COMPONENT_PLIST"
pkgbuild \
    --root "$PKG_ROOT" \
    --component-plist "$COMPONENT_PLIST" \
    --install-location /Applications \
    --scripts Packaging/pkg/scripts \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    "$COMPONENT_PKG" >/dev/null
rm -rf "$PKG_ROOT" "$COMPONENT_PLIST"

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

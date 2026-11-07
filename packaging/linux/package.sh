#!/usr/bin/env bash
# Packages a Release build into IPTVX-<version>-linux-<arch>.AppImage.
#
#   packaging/linux/package.sh <build-dir> <version> <x86_64|aarch64> [out-dir]
#
# Uses linuxdeploy + linuxdeploy-plugin-qt (downloaded into the build dir).
# QMAKE must point at the Qt installation's qmake.
set -euo pipefail

BUILD="$1"; VERSION="$2"; ARCH="$3"; OUT="${4:-dist}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APPDIR="$BUILD/AppDir"
TOOLS="$BUILD/linuxdeploy"
mkdir -p "$OUT" "$TOOLS"
OUT="$(cd "$OUT" && pwd)"

rm -rf "$APPDIR"
DESTDIR="$APPDIR" cmake --install "$BUILD" --prefix /usr

fetch() { # fetch <url> <file>
    [ -x "$TOOLS/$2" ] || { curl -fsSL -o "$TOOLS/$2" "$1"; chmod +x "$TOOLS/$2"; }
}
fetch "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$ARCH.AppImage" \
      "linuxdeploy-$ARCH.AppImage"
fetch "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$ARCH.AppImage" \
      "linuxdeploy-plugin-qt-$ARCH.AppImage"

export PATH="$TOOLS:$PATH"
export APPIMAGE_EXTRACT_AND_RUN=1          # no FUSE needed on CI
export QML_SOURCES_PATHS="$ROOT/src/ui/qml"
export EXTRA_QT_PLUGINS="multimedia"
export EXTRA_QT_MODULES="multimedia"
export EXTRA_PLATFORM_PLUGINS="libqwayland-generic.so;libqwayland-egl.so"
export OUTPUT="$OUT/IPTVX-$VERSION-linux-$ARCH.AppImage"

"linuxdeploy-$ARCH.AppImage" \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/usr/share/applications/io.github.birdra1n.iptvx.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/256x256/apps/io.github.birdra1n.iptvx.png" \
    --plugin qt \
    --output appimage
echo "Created $OUTPUT"

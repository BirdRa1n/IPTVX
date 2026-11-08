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
# Ship the Wayland platform plugin(s) next to xcb. Their file names changed
# across Qt versions (libqwayland-generic.so → libqwayland.so), so take
# whatever this Qt provides.
QT_PLUGINS_DIR="$("${QMAKE:-qmake}" -query QT_INSTALL_PLUGINS)"
EXTRA_PLATFORM_PLUGINS="$( (cd "$QT_PLUGINS_DIR/platforms" && ls libqwayland*.so 2>/dev/null) | paste -sd ';' - || true)"
export EXTRA_PLATFORM_PLUGINS
echo "Extra platform plugins: ${EXTRA_PLATFORM_PLUGINS:-none}"
export OUTPUT="$OUT/IPTVX-$VERSION-linux-$ARCH.AppImage"

# Phase 1: deploy libraries, plugins and QML modules into the AppDir.
"linuxdeploy-$ARCH.AppImage" \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/usr/share/applications/io.github.birdra1n.iptvx.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/256x256/apps/io.github.birdra1n.iptvx.png" \
    --plugin qt

# Phase 2: prune what IPTVX never loads (other Qt Quick Controls styles,
# widget styles, particles, vector images…). IPTVX uses the Basic style only.
U="$APPDIR/usr"
for s in FluentWinUI3 Fusion IOS Imagine Macos MacOS Material Native Universal; do
    rm -f "$U/lib/libQt6QuickControls2$s".so* "$U/lib/libQt6QuickControls2${s}StyleImpl".so*
done
rm -f "$U"/lib/libQt6QuickNativeStyle.so* "$U"/lib/libQt6QuickParticles.so* \
      "$U"/lib/libQt6QuickShapesDesignHelpers.so* "$U"/lib/libQt6QuickVectorImage*.so*
for d in FluentWinUI3 Fusion Imagine Material Native Universal iOS macOS designer; do
    rm -rf "$U/qml/QtQuick/Controls/$d"
done
rm -rf "$U/qml/QtQuick/NativeStyle" "$U/qml/QtQuick/Particles" "$U/qml/QtQuick/VectorImage" \
       "$U/qml/QtQuick/Shapes/DesignHelpers" "$U/plugins/styles"
find "$U/plugins" "$U/qml" -type f -name '*.so' \( -iname '*fluentwinui3*' -o -iname '*fusion*' \
    -o -iname '*imagine*' -o -iname '*material*' -o -iname '*universal*' -o -iname '*nativestyle*' \
    -o -iname '*particles*' -o -iname '*vectorimage*' -o -iname '*designhelpers*' \) -delete
find "$U/plugins/sqldrivers" -type f ! -iname '*sqlite*' -delete 2>/dev/null || true

# Safety net: no shipped ELF may miss a library it links against.
missing=0
while IFS= read -r -d '' so; do
    if LD_LIBRARY_PATH="$U/lib" ldd "$so" 2>/dev/null | grep -q "not found"; then
        echo "error: $so has unresolved libraries:" >&2
        LD_LIBRARY_PATH="$U/lib" ldd "$so" | grep "not found" >&2
        missing=1
    fi
done < <(find "$U/bin" "$U/lib" "$U/plugins" "$U/qml" -type f \( -name '*.so*' -o -perm -u+x \) -print0)
[ "$missing" -eq 0 ] || exit 1

# Phase 3: build the AppImage. xz gives the smallest download.
export LDAI_COMP=xz
"linuxdeploy-$ARCH.AppImage" --appdir "$APPDIR" --output appimage
echo "Created $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"

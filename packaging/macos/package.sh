#!/usr/bin/env bash
# Packages a Release build into IPTVX-<version>-macos-<arch>.zip.
#
#   packaging/macos/package.sh <build-dir> <version> <arm64|x86_64> [out-dir]
#
# The Qt frameworks from the Qt installer are universal; they are thinned to
# the target architecture so each download only carries what it runs.
# The app is ad-hoc signed (required on Apple silicon); it is not notarized.
set -euo pipefail

BUILD="$1"; VERSION="$2"; ARCH="$3"; OUT="${4:-dist}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$BUILD/src/app/IPTVX.app"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"

macdeployqt "$APP" -qmldir="$ROOT/src/ui/qml" -always-overwrite

# ---- Prune what IPTVX never loads ------------------------------------------
# macdeployqt copies whole QML modules: every Qt Quick Controls style, the
# widget-based macOS style (which drags in QtWidgets), particles, vector
# images… IPTVX uses the Basic controls style only.
C="$APP/Contents"
STYLES="FluentWinUI3 Fusion IOS Imagine Macos MacOS Material Native Universal"
for s in $STYLES; do
    rm -rf "$C/Frameworks/QtQuickControls2$s.framework" \
           "$C/Frameworks/QtQuickControls2${s}StyleImpl.framework"
done
rm -rf "$C/Frameworks/QtQuickNativeStyle.framework" \
       "$C/Frameworks/QtWidgets.framework" \
       "$C/Frameworks/QtQuickParticles.framework" \
       "$C/Frameworks/QtQuickShapesDesignHelpers.framework" \
       "$C/Frameworks/QtQuickVectorImage.framework" \
       "$C/Frameworks/QtQuickVectorImageGenerator.framework" \
       "$C/Frameworks/QtQuickVectorImageHelpers.framework" \
       "$C/PlugIns/styles"
for d in FluentWinUI3 Fusion Imagine Material Native Universal iOS macOS designer; do
    rm -rf "$C/Resources/qml/QtQuick/Controls/$d"
done
rm -rf "$C/Resources/qml/QtQuick/NativeStyle" "$C/Resources/qml/QtQuick/Particles" \
       "$C/Resources/qml/QtQuick/VectorImage" "$C/Resources/qml/QtQuick/Shapes/DesignHelpers"
find "$C/PlugIns/quick" -type f \( -iname '*fluentwinui3*' -o -iname '*fusion*' -o -iname '*imagine*' \
    -o -iname '*material*' -o -iname '*universal*' -o -iname '*iosstyle*' -o -iname '*macosstyle*' \
    -o -iname '*nativestyle*' -o -iname '*particles*' -o -iname '*vectorimage*' -o -iname '*designhelpers*' \) -delete
# IPTVX only uses SQLite.
find "$C/PlugIns/sqldrivers" -type f ! -iname '*sqlite*' -delete 2>/dev/null || true

# Safety net: every @rpath library still referenced must still be shipped.
missing=0
while IFS= read -r -d '' bin; do
    file "$bin" | grep -q "Mach-O" || continue
    while read -r dep; do
        lib="${dep#@rpath/}"
        if [ ! -e "$C/Frameworks/$lib" ]; then
            echo "error: $(basename "$bin") needs $dep, which was pruned" >&2
            missing=1
        fi
    done < <(otool -L "$bin" | awk 'NR>1 {print $1}' | grep '^@rpath/' || true)
done < <(find "$C/MacOS" "$C/Frameworks" "$C/PlugIns" "$C/Resources/qml" -type f -print0)
[ "$missing" -eq 0 ] || exit 1

# ---- Thin, sign, archive -----------------------------------------------------
ditto --arch "$ARCH" "$APP" "$WORK/IPTVX.app"

codesign --force --deep --sign - "$WORK/IPTVX.app"
codesign --verify --deep --strict "$WORK/IPTVX.app"

NAME="IPTVX-$VERSION-macos-$ARCH.zip"
ditto -c -k --sequesterRsrc --keepParent "$WORK/IPTVX.app" "$OUT/$NAME"
echo "Created $OUT/$NAME ($(du -h "$OUT/$NAME" | cut -f1))"

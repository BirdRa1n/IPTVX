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
# IPTVX only uses SQLite: drop the other SQL drivers macdeployqt copies.
find "$APP/Contents/PlugIns/sqldrivers" -type f ! -iname '*sqlite*' -delete 2>/dev/null || true

# Thin every Mach-O to the target architecture.
ditto --arch "$ARCH" "$APP" "$WORK/IPTVX.app"

codesign --force --deep --sign - "$WORK/IPTVX.app"
codesign --verify --deep --strict "$WORK/IPTVX.app"

NAME="IPTVX-$VERSION-macos-$ARCH.zip"
ditto -c -k --sequesterRsrc --keepParent "$WORK/IPTVX.app" "$OUT/$NAME"
echo "Created $OUT/$NAME"

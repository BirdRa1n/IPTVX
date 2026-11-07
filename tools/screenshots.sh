#!/usr/bin/env bash
# Regenerates the documentation gallery in docs/screenshots/.
#
#   tools/screenshots.sh [path/to/IPTVX-binary]
#
# Uses the synthetic docs/demo/demo.m3u in a sandboxed profile. On macOS the
# captures include the native window frame (traffic lights, shadow) through
# `screencapture -l`, which needs the Screen Recording permission for your
# terminal; without it the app composites an equivalent frame.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${1:-$ROOT/build/debug/src/app/IPTVX.app/Contents/MacOS/IPTVX}"
OUT="$ROOT/docs/screenshots"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT" "$WORK/plain" "$WORK/play"

# The source name comes from the file name.
cp "$ROOT/docs/demo/demo.m3u" "$WORK/plain/Home Playlist.m3u"

# Playback shots need a stream that actually plays offline: point the first
# channel at a generated 30 s tone.
python3 -I - "$WORK/tone.wav" <<'PY'
import math, struct, sys, wave
w = wave.open(sys.argv[1], "wb")
w.setnchannels(1); w.setsampwidth(2); w.setframerate(8000)
w.writeframes(b"".join(struct.pack("<h", int(600 * math.sin(i / 8000 * 2 * math.pi * 220))) for i in range(8000 * 30)))
w.close()
PY
python3 -I - "$ROOT/docs/demo/demo.m3u" "$WORK/play/Home Playlist.m3u" "file://$WORK/tone.wav" <<'PY'
import sys
src, dst, url = sys.argv[1:4]
text = open(src).read().replace("https://stream.example.com/live/news-one-hd.m3u8", url, 1)
open(dst, "w").write(text)
PY

shoot() { # shoot <name> <playlist> [VAR=value ...]
    local name=$1 list=$2; shift 2
    env IPTVX_SEED_PLAYLIST="$list" IPTVX_SCREENSHOT_NATIVE=1 IPTVX_WINDOW_SIZE=1440x900 \
        IPTVX_SCREENSHOT="$OUT/$name.png" "$@" "$BIN" -AppleLanguages "(en)"
    if command -v sips >/dev/null; then sips -Z 1800 "$OUT/$name.png" >/dev/null; fi
}

PLAIN="$WORK/plain/Home Playlist.m3u"
PLAY="$WORK/play/Home Playlist.m3u"
shoot dashboard-dark       "$PLAY"  IPTVX_PAGE=home     IPTVX_APPEARANCE=dark
shoot dashboard-light      "$PLAY"  IPTVX_PAGE=home     IPTVX_APPEARANCE=light
shoot live-dark            "$PLAY"  IPTVX_PAGE=live     IPTVX_PLAY=1 IPTVX_APPEARANCE=dark
shoot live-light           "$PLAY"  IPTVX_PAGE=live     IPTVX_PLAY=1 IPTVX_APPEARANCE=light
shoot command-palette-dark "$PLAIN" IPTVX_PAGE=live     IPTVX_PALETTE=news IPTVX_APPEARANCE=dark
shoot add-source-light     "$PLAIN" IPTVX_PAGE=home     IPTVX_SHEET=add IPTVX_APPEARANCE=light
shoot settings-dark        "$PLAIN" IPTVX_PAGE=settings IPTVX_APPEARANCE=dark
shoot mini-player-light    "$PLAY"  IPTVX_PAGE=home     IPTVX_PLAY=1 IPTVX_APPEARANCE=light
shoot mini-player-dark     "$PLAY"  IPTVX_PAGE=settings IPTVX_PLAY=1 IPTVX_APPEARANCE=dark
echo "Gallery written to $OUT"

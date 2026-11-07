#!/usr/bin/env bash
# Cuts an IPTVX release.
#
#   tools/release.sh 0.2.0
#
# 1. checks the working tree is clean and on main, in sync with origin
# 2. sets project(VERSION 0.2.0) in CMakeLists.txt and commits it
# 3. creates the annotated tag v0.2.0 and pushes branch + tag
#
# The tag push starts .github/workflows/release.yml, which builds macOS
# (arm64 + x86_64), Linux (x86_64 + aarch64) and Windows (x64), uploads the
# packages and publishes the GitHub release. Follow it with:
#   gh run watch
set -euo pipefail

VERSION="${1:-}"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "usage: tools/release.sh <major.minor.patch>" >&2
    exit 2
fi
TAG="v$VERSION"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

[ -z "$(git status --porcelain)" ] || { echo "error: working tree is not clean" >&2; exit 1; }
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "error: release from main" >&2; exit 1; }
git fetch --quiet origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "error: main is not in sync with origin/main" >&2; exit 1; }
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "error: tag $TAG already exists" >&2; exit 1
fi

CURRENT=$(sed -nE 's/^ *VERSION ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' CMakeLists.txt | head -n1)
if [ "$CURRENT" != "$VERSION" ]; then
    perl -0pi -e "s/(project\(IPTVX\s+VERSION )\d+\.\d+\.\d+/\${1}$VERSION/" CMakeLists.txt
    git add CMakeLists.txt
    git commit -m "chore(release): $TAG"
fi

git tag -a "$TAG" -m "IPTVX $VERSION"
git push origin main "$TAG"

echo "Released $TAG — the Release workflow is building it."
command -v gh >/dev/null && echo "Watch it with: gh run watch"

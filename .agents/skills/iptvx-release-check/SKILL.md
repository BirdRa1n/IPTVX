---
name: iptvx-release-check
description: Use before finishing any IPTVX change, opening a pull request or cutting a release, to run the full verification gate.
---

# IPTVX verification gate

Run from the repository root with `CMAKE_PREFIX_PATH` pointing at Qt.

1. `cmake --preset ci && cmake --build --preset ci` — warnings are errors.
2. `ctest --preset ci` — all suites pass.
3. `cmake --build --preset ci --target all_qmllint` — no output.
4. UI changed? Capture screenshots with the developer mode (see
   `iptvx-qml-ui`) in light and dark and inspect them.
5. Strings changed? `--target update_translations` and no unfinished
   entries left in `i18n/iptvx_pt_BR.ts`.
6. Docs: update `docs/ROADMAP.md` statuses and any affected document.
7. Diff review: no real playlists/URLs/credentials, no debug leftovers, no
   AI attribution trailers in commits.
8. Commits: English Conventional Commits, small and focused.

Report what ran, what passed, and anything skipped with the reason.

## Cutting a release (maintainer asks for it)

1. Run the gate above on `main`, push `main`.
2. `tools/release.sh X.Y.Z` — bumps `project(VERSION)`, tags `vX.Y.Z`,
   pushes; the Release workflow builds and publishes (`gh run watch`).
3. Check the release lists the five platform assets plus `SHA256SUMS.txt`
   (names in docs/RELEASING.md) and that the notes read well — the updater
   shows them to users.

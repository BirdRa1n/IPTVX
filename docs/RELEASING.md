# Releasing IPTVX

[Back to README](../README.md)

Releases are built by GitHub Actions from a version tag and published on
[GitHub Releases](https://github.com/BirdRa1n/IPTVX/releases). The app's
updater reads the same releases, so publishing one is all it takes to
update every installation.

## Cutting a release

```bash
tools/release.sh 0.2.0
```

The script:

1. checks the working tree is clean, on `main` and in sync with `origin/main`;
2. sets `project(IPTVX VERSION 0.2.0)` in `CMakeLists.txt` and commits
   `chore(release): v0.2.0`;
3. creates the annotated tag `v0.2.0` and pushes `main` and the tag.

Follow the build with `gh run watch` (or the **Actions** tab). When it is
green the release is public. Edit the generated notes with
`gh release edit v0.2.0 --notes-file notes.md` if you want — the updater
shows them (Markdown) to users.

To rebuild an existing tag (e.g. after fixing the workflow), run the
**Release** workflow manually from the Actions tab with `tag: v0.2.0`.

## What the workflow does

`.github/workflows/release.yml`:

| Step | Details |
|---|---|
| Prepare | Fails if the tag does not match `project(VERSION)`; creates a **draft** release with generated notes |
| Build (in parallel) | macOS arm64 and macOS x86_64 (cross-compiled on Apple silicon), Linux x86_64 (`ubuntu-22.04`) and aarch64 (`ubuntu-22.04-arm`), Windows x64 (`windows-2022`, MSVC) — Qt 6.12.0 |
| Package | `packaging/macos/package.sh`, `packaging/linux/package.sh`, `packaging/windows/package.ps1` |
| Upload | Each job uploads its package to the draft |
| Publish | Adds `SHA256SUMS.txt`, then publishes the release and marks it *latest* |

Because the release stays a draft until every build succeeded, the updater
(`/releases/latest` ignores drafts) never sees a half-uploaded release.

## Release assets

The updater picks the asset by its **name suffix** — keep these names:

| Platform | Asset |
|---|---|
| macOS Apple silicon | `IPTVX-<version>-macos-arm64.zip` |
| macOS Intel | `IPTVX-<version>-macos-x86_64.zip` |
| Linux x86_64 | `IPTVX-<version>-linux-x86_64.AppImage` |
| Linux ARM64 | `IPTVX-<version>-linux-aarch64.AppImage` |
| Windows x64 | `IPTVX-<version>-windows-x64-setup.exe` |
| Checksums | `SHA256SUMS.txt` |

## How the in-app updater works

`src/core/update/` + `src/ui/Updates.*`:

1. ~4 s after launch (unless *Settings › Check for updates on launch* is off)
   the app calls `GET https://api.github.com/repos/BirdRa1n/IPTVX/releases/latest`.
2. If the tag is newer than the running version it picks the asset for the
   running platform. On macOS an Intel build running under Rosetta picks the
   **arm64** build; Windows on ARM keeps the x64 build.
3. The user sees the release notes and *Download*. The asset is streamed to
   the cache folder and verified against its size and the SHA-256 digest
   GitHub publishes for it.
4. *Restart and update*:

| Platform | Installation |
|---|---|
| macOS | A detached script waits for IPTVX to quit, unpacks the zip, swaps `IPTVX.app` in place (keeping the old one until the swap succeeds) and reopens it. If the app's folder is not writable, the zip is revealed in Finder instead. |
| Linux | When running as an AppImage (`$APPIMAGE`), the new AppImage replaces it and is started. Otherwise the downloaded AppImage is made executable and started. |
| Windows | The per-user Inno Setup installer runs with `/SILENT`; it closes IPTVX if needed and relaunches it when done. |

Developer sandboxes (`IPTVX_SANDBOX`, screenshots, seeding) never call the
API. Preview the UI with `IPTVX_UPDATE_PREVIEW=0.9.0`. The repository is a
CMake cache variable: `-DIPTVX_UPDATE_REPO=owner/name` (for forks).

## Signing

Builds are not code-signed by a certificate yet:

* **macOS** apps are ad-hoc signed (required on Apple silicon) but not
  notarized, so the first launch of a browser-downloaded copy needs
  right-click › **Open** (or `xattr -dr com.apple.quarantine IPTVX.app`).
  Updates installed by the app itself are not quarantined.
* **Windows** SmartScreen may warn on the first installer run
  (*More info › Run anyway*).

Adding Developer ID signing + notarization and Authenticode signing is on
the [roadmap](ROADMAP.md#distribution).

## Building a package locally

```bash
# macOS (on the target architecture or cross with CMAKE_OSX_ARCHITECTURES)
cmake -S . -B build/pkg -G Ninja -DCMAKE_BUILD_TYPE=Release -DIPTVX_BUILD_TESTS=OFF \
      -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build/pkg
packaging/macos/package.sh build/pkg 0.2.0 arm64 dist

# Linux
QMAKE=$QT_DIR/bin/qmake packaging/linux/package.sh build/pkg 0.2.0 x86_64 dist

# Windows (Developer PowerShell, Inno Setup 6 installed)
./packaging/windows/package.ps1 -BuildDir build/pkg -Version 0.2.0 -OutDir dist
```

Remove the unused SQL drivers from your Qt installation first (or ignore
macdeployqt's errors about PostgreSQL/ODBC/Mimer client libraries): IPTVX
only ships the SQLite driver.

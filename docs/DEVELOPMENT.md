# Development guide

## Prerequisites

| Platform | Qt | Toolchain | Extra packages |
|---|---|---|---|
| **macOS** 13+ | Qt 6.9+ (`macos` kit) via the Qt Online Installer | Xcode Command Line Tools | — |
| **Windows** 10+ | Qt 6.9+ `msvc2022_64` | Visual Studio 2022 | — |
| **Linux** | Qt 6.9+ `gcc_64` (installer or `aqtinstall`) | GCC 12+/Clang 15+ | `libgl1-mesa-dev libxkbcommon-dev libpulse-dev libva-dev` (Debian/Ubuntu) |

Required Qt modules: Core, Gui, Network, Sql (SQLite driver), Concurrent, Qml,
Quick, QuickControls2, Multimedia, Linguist Tools (and Test for the tests).

The Qt Online Installer ships CMake and Ninja under `Qt/Tools/`; add them to
`PATH` if they are not installed system-wide.

## Configure, build, test

```bash
export CMAKE_PREFIX_PATH=/path/to/Qt/6.x/<kit>

cmake --preset debug          # or: release, ci
cmake --build --preset debug
ctest --preset debug          # unit tests
cmake --build --preset debug --target all_qmllint   # QML lint
```

| Preset | Build type | Notes |
|---|---|---|
| `debug` | Debug | LTO off |
| `release` | Release | LTO on |
| `ci` | Release | Warnings are errors, LTO off |

CMake options: `IPTVX_BUILD_TESTS` (ON), `IPTVX_WARNINGS_AS_ERRORS` (OFF),
`IPTVX_ENABLE_LTO` (ON), `IPTVX_BUILD_TOOLS` (OFF — icon renderer).

Regenerate the app icons after editing `resources/icons/iptvx.svg`:

```bash
cmake --preset debug -DIPTVX_BUILD_TOOLS=ON && cmake --build --preset debug --target icons
```

## Developer mode (sandbox, seeding, screenshots)

Environment variables read by `src/app/DevTools.cpp`:

| Variable | Effect |
|---|---|
| `IPTVX_SANDBOX=1` | Isolated profile (`QStandardPaths` test mode + INI `QSettings`, wiped on start) |
| `IPTVX_SEED_PLAYLIST=<file>` | Add the file as a source if the library is empty (implies sandbox) |
| `IPTVX_PAGE=home\|live\|settings` | Initial page |
| `IPTVX_APPEARANCE=light\|dark\|system` | Initial appearance |
| `IPTVX_PALETTE=<query>` | Open the command palette with the query typed |
| `IPTVX_PLAY=<n>` | Select channel number `n` once the catalog loads (autoplay check) |
| `IPTVX_SCREENSHOT=<out.png>` | Save a window capture and quit (implies sandbox) |
| `IPTVX_SCREENSHOT_DELAY=<ms>` | Delay before the capture (default 2500) |

Example — capture the Live TV page in light mode:

```bash
IPTVX_SEED_PLAYLIST=tests/data/sample.m3u IPTVX_PAGE=live IPTVX_APPEARANCE=light \
IPTVX_SCREENSHOT=/tmp/live.png ./build/debug/src/app/IPTVX.app/Contents/MacOS/IPTVX
```

Use this to verify UI changes visually (it is how `docs/assets` is produced).

## Translations

```bash
cmake --build --preset debug --target update_translations   # lupdate → i18n/*.ts
# translate i18n/iptvx_pt_BR.ts (Qt Linguist or by hand)
cmake --build --preset debug                                # lrelease is automatic
```

Every user-visible string goes through `qsTr()` (QML) or `tr()` (C++).

## Adding code

| You are adding… | Put it in | Remember |
|---|---|---|
| Parser / provider / storage logic | `src/core/<module>/` + `src/core/CMakeLists.txt` | No GUI includes; add a test in `tests/core/` |
| A model or object exposed to QML | `src/ui/models/` or `src/ui/` + `SOURCES` in `src/ui/CMakeLists.txt` | `QML_ELEMENT`, `QML_UNCREATABLE` if owned by `Library` |
| A QML file | `src/ui/qml/<area>/` + `QML_FILES` | Use `Theme` tokens; run `all_qmllint` |
| A singleton QML file | as above + `QT_QML_SINGLETON_TYPE` property | |
| A DB change | new entry at the end of `kMigrations` | Never edit released migrations |
| A test | `tests/core/tst_*.cpp` + `iptvx_add_test()` | Synthetic fixtures only (`example.com`) |

> **moc gotcha:** raw string literals (`R"(...)"`) inside a `Q_OBJECT` test
> file can make moc skip the file. Put JSON/M3U payloads in
> `tests/data/` instead.

## Packaging (planned)

* macOS: `macdeployqt IPTVX.app -qmldir=src/ui/qml -dmg`
* Windows: `windeployqt --qmldir src\ui\qml IPTVX.exe`
* Linux: AppImage via `linuxdeploy` + `linuxdeploy-plugin-qt`

See [ROADMAP.md](ROADMAP.md).

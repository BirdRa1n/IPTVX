# AGENTS.md — guidance for AI coding agents

IPTVX is a Qt 6 / C++20 IPTV player (M3U, Xtream) with a QML UI. These rules
apply to every agent (Claude Code, Codex, Copilot, Cursor, …). Read the
document for the area you touch; do not load everything.

## Bootstrap

```bash
export CMAKE_PREFIX_PATH=/path/to/Qt/6.x/<kit>   # macOS dev box: ~/Qt/6.12.0/macos
# If cmake/ninja are not on PATH, the Qt installer ships them:
# export PATH="$HOME/Qt/Tools/CMake/CMake.app/Contents/bin:$HOME/Qt/Tools/Ninja:$PATH"
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
cmake --build --preset debug --target all_qmllint
```

All four must be clean before you finish. Warnings count: CI builds with
`-Werror` (`ci` preset).

## Architecture invariants

- Layers: `src/app` → `src/ui` → `src/core`. **`core` never includes Qt Gui,
  Qml, Quick or Multimedia.** See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Catalog data lives in `ChannelStore` and is shared as
  `std::shared_ptr<const ChannelStore>`. Never copy it into per-item objects,
  `QVariantList`s or QML arrays.
- Heavy work (parsing, JSON conversion) runs via `QtConcurrent::run`; results
  return to the GUI thread. Stale async results are dropped (generation
  counters), never applied.
- QML talks to C++ only through `Library` (singleton) and the models in
  `src/ui/models`.
- Database changes: append to `kMigrations` in `src/core/storage/Database.cpp`.
  Never edit a released migration.

## Memory is a feature

Follow [docs/MEMORY.md › Rules for new code](docs/MEMORY.md#rules-for-new-code):
stream inputs, keep one catalog resident, decode images at display size,
no per-item QObjects, add a footprint bound test for new scaling structures.

## UI rules

- Styling only through `Theme` tokens (`src/ui/qml/theme/Theme.qml`); see
  [docs/DESIGN.md](docs/DESIGN.md). No hard-coded colors/durations in
  components (decorative illustration colors in a single place are the
  exception).
- Never name a QML property `on<Something>` — it is parsed as a signal handler
  and the type fails at run time (qmllint does not catch it).
- Both appearances are required: check every UI change in `IPTVX_APPEARANCE=dark`
  **and** `light`. Use `Theme.accentText` (not `accent`) for accent-colored
  text/icons; `accent` is a fill paired with `accentForeground`.
- Files with delegates use `pragma ComponentBehavior: Bound` and
  `required property` roles.
- Every user-visible string uses `qsTr()` / `tr()`; update `i18n/iptvx_pt_BR.ts`
  (`--target update_translations`, then translate new entries).
- Respect `Theme.reduceMotion`; icon-only buttons need `Accessible.name`.
- **Verify UI changes visually** with the developer mode, then read the PNG:

  ```bash
  IPTVX_SEED_PLAYLIST=tests/data/sample.m3u IPTVX_PAGE=live IPTVX_APPEARANCE=dark \
  IPTVX_SCREENSHOT=/tmp/shot.png ./build/debug/src/app/IPTVX.app/Contents/MacOS/IPTVX
  ```

  Seeding/screenshots always run in a sandboxed profile. `IPTVX_PALETTE=<query>`
  opens the command palette for a capture.

## Code conventions

- C++20, `.clang-format`; Qt string safety macros are on — use `u"…"_s`,
  `"…"_L1`, `QStringLiteral`.
- New source files must be listed in the owning `CMakeLists.txt`
  (`qt_add_library` sources, `SOURCES` or `QML_FILES` of the QML module).
- QML singletons need `QT_QML_SINGLETON_TYPE` in `src/ui/CMakeLists.txt`.
- Tests: `tests/core/tst_<name>.cpp` registered with `iptvx_add_test()`.
  Keep payloads in `tests/data/` (raw string literals can break moc).
- Fixtures, docs and commit messages use **synthetic data only**
  (`example.com`, invented names). Never commit real playlists, provider
  URLs or credentials, and never log credentials.

## Commits

- English, Conventional Commits (`feat(core): …`, `fix(ui): …`, `docs: …`).
- Small, focused commits that each build and pass tests — leave a readable
  development trail rather than one large commit.
- **Do not add `Co-Authored-By` trailers or any AI attribution** to commits
  or PR descriptions in this repository.
- Commit/push only when the maintainer asks.

## Where to look

| Task | Start here |
|---|---|
| Parsing playlists | `src/core/parser/M3uParser.*`, `tests/core/tst_m3uparser.cpp` |
| Xtream / new providers | `src/core/provider/`, `src/core/service/PlaylistLoader.*` |
| Persistence | `src/core/storage/` |
| QML ↔ C++ | `src/ui/Library.*`, `src/ui/models/` |
| Screens & components | `src/ui/qml/pages/`, `src/ui/qml/components/` |
| Player | `src/ui/qml/player/VideoPlayer.qml` |
| Build system | `CMakeLists.txt`, `cmake/CompilerSettings.cmake`, `CMakePresets.json` |
| What to build next | [docs/ROADMAP.md](docs/ROADMAP.md) |

Task-specific playbooks live in `.agents/skills/*/SKILL.md`.

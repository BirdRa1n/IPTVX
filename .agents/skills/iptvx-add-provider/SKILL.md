---
name: iptvx-add-provider
description: Use when adding or extending a content provider in IPTVX (Xtream VOD/series, Stalker portals, XMLTV EPG) or any new way of turning a Source into channels.
---

# Adding a provider to IPTVX

## Steps

1. **Pure helpers first** — put URL builders and JSON/XML → model conversion
   in a namespace of free functions (see `xtream::` in
   `src/core/provider/XtreamClient.*`). They must be unit-testable without
   network.
2. **Fixtures** — add synthetic payloads under `tests/data/<provider>/`
   (`example.com` hosts, invented names). No raw string literals in test
   files (moc can skip them).
3. **Tests** — `tests/core/tst_<provider>.cpp`, registered in
   `tests/CMakeLists.txt` with `iptvx_add_test()`.
4. **Async client** — a `QObject` that owns its `QNetworkReply`s, supports
   `abort()`, and runs conversion through `QtConcurrent::run`. Callbacks
   are silent after abort.
5. **Wire into `PlaylistLoader::load()`** — add a `SourceType` case; use the
   generation counter so stale results are ignored.
6. **Schema** — if the source needs new fields, add them to `Source`, a new
   migration at the end of `kMigrations`, and `SourceRepository` binds.
7. **UI** — add a tab/fields in `src/ui/qml/sheets/AddSourceSheet.qml` and a
   `Library::add<Provider>()` invokable. Translate new strings.
8. Update `docs/ROADMAP.md` status and, if the data flow changed,
   `docs/ARCHITECTURE.md`.

## Memory checklist

- Stream large responses (`QXmlStreamReader` for XMLTV; free one JSON
  document before parsing the next).
- Produce a `ChannelStore` (or a similarly compact columnar store for VOD) —
  never a list of QObjects.
- `squeeze()` the store before publishing it.

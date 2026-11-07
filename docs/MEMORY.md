# Memory strategy

Low memory use is a primary goal of IPTVX, not an afterthought. Large IPTV
catalogs contain 50 000–150 000 entries; a naïve "one object with a handful of
`QString`s per channel" model easily costs 30–60 MB before any UI is drawn.

## What we do today

### 1. Columnar channel storage — `ChannelStore`

```
Record (44 bytes, fixed)                       UTF-8 arena (one QByteArray)
┌─────────────┬────────────┬──────┬─────────┐  ┌──────────────────────────────┐
│ name  span  │ url  span  │ logo │ tvg-id  │  │News One HDhttp://…news.m3u8… │
│ (off,len)   │ (off,len)  │ span │ span    │  └──────────────────────────────┘
├─────────────┴────────────┴──────┴─────────┤
│ group id u16 │ UA id u16 │ referrer id u16 │──► StringTable (deduplicated)
│ catchup u16  │ flags u8                    │
└───────────────────────────────────────────┘
```

* **One allocation for all text** instead of 4–7 heap blocks per channel
  (each with ~32 bytes of allocator + `QArrayData` overhead).
* **UTF-8 instead of UTF-16**: playlist text is mostly ASCII, so it is about
  half the size of the equivalent `QString` data.
* **Interning** of values that repeat thousands of times (group titles, user
  agents, referrers) into 16-bit ids.
* **`squeeze()`** after loading releases growth slack and the interning
  hashes.
* `QString`s are created **only in `data()`**, i.e. for the ~20 rows on
  screen.

Measured by `tst_channelstore::footprintIsCompact`: a 10 000-channel store
with realistic names/URLs stays under 1.28 MB (bound asserted in the test).

### 2. Streaming input

* `M3uParser` reads one line at a time into a reused buffer
  (`QIODevice::readLineInto`), so the file is never fully in memory.
* `PlaylistLoader` streams remote playlists **to disk** through `QSaveFile`
  with a 256 KiB network read buffer and parses them from the file.
* Xtream: the categories JSON document is freed before the (larger) streams
  document is parsed.

### 3. One catalog at a time

`Library::selectSource` releases the current store **before** loading the
next, so two catalogs never coexist.

### 4. Views

* `ListView` with `reuseItems: true` and a small `cacheBuffer`: object count
  is proportional to the viewport, not the catalog.
* The filter is a `std::vector<quint32>` of indices (4 bytes per visible
  row), shrunk after filtering.
* Pages are destroyed when you navigate away (`StackView.replace`).

### 5. Images

* Logos are decoded at display size (`sourceSize` × device pixel ratio) and
  loaded asynchronously; recycled delegates release them.
* `ArtworkNetworkFactory` gives QML a 128 MiB **disk** HTTP cache, so
  artwork is revalidated rather than re-downloaded or kept in RAM.
* Icons are vector paths drawn by Qt Quick Shapes — no icon font or image
  atlas to load.

### 6. Runtime configuration

* SQLite page cache limited to 2 MiB (`PRAGMA cache_size = -2048`).
* QML compiled ahead of time: no QML source parsing at start-up.
* `QT_NO_DEBUG_OUTPUT` in release builds, LTO enabled by default.

## Rules for new code

1. **No per-item `QObject`s** for catalog data. Use `QAbstractListModel` over
   compact storage.
2. **Never copy a catalog.** Share `std::shared_ptr<const ChannelStore>` and
   keep indices.
3. **Stream, don't slurp.** Prefer `QIODevice` + incremental parsing
   (`QXmlStreamReader` for XMLTV) over `readAll()` on large inputs.
4. **Decode images at display size** and set `asynchronous: true`.
5. **Release before acquire** when switching large datasets.
6. **Measure.** Use `ChannelStore::memoryFootprint()` and add a bound test when
   you add a structure that scales with catalog size.

## Measuring

* macOS: `footprint IPTVX` or Instruments › Allocations.
* Linux: `heaptrack ./IPTVX`, `/usr/bin/time -v`.
* Windows: Visual Studio Diagnostic Tools › Memory Usage.
* In-app: Settings › About › *Channel catalog in memory*.

## Next steps

See [ROADMAP.md](ROADMAP.md#performance--memory): memory-mapped cache files
for catalogs, an on-disk FTS index for search over huge catalogs, and a
streaming XMLTV parser that keeps only a time window of programmes.

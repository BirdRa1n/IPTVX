# Architecture

IPTVX is split into three CMake targets with a strict, one-way dependency
direction:

```mermaid
flowchart LR
    app["iptvx (executable)<br/>src/app"] --> ui["iptvx_ui (static QML module IPTVX.UI)<br/>src/ui"]
    ui --> core["iptvx_core (static lib, GUI-free)<br/>src/core"]
    tests["tests/*"] --> core
    core --> QtCore[Qt Core / Network / Sql / Concurrent]
    ui --> QtQuick[Qt Quick / Controls / Multimedia]
```

| Layer | May depend on | Must not depend on |
|---|---|---|
| `core` | Qt Core, Network, Sql, Concurrent | Qt Gui, Qml, Quick, Multimedia, `ui`, `app` |
| `ui` | `core`, Qt Quick, Controls, Multimedia | `app` |
| `app` | `ui`, `core` | — |

Keeping `core` GUI-free means every parser, provider and repository is unit
tested without a display, and could be reused by a CLI or another front end.

## Core (`src/core`)

| Module | Responsibility |
|---|---|
| `model/ChannelStore` | Compact, append-only columnar storage of a catalog. Text in one UTF-8 arena; group/user-agent/referrer interned to 16-bit ids. Published as `std::shared_ptr<const ChannelStore>` (immutable, thread-safe reads). |
| `model/Source` | A configured playlist/account (M3U file, M3U URL, Xtream, Stalker). |
| `parser/M3uParser` | Streaming extended-M3U parser (one reused line buffer, cancellable). |
| `provider/XtreamClient` | Async Xtream Codes client + pure URL/JSON helpers. |
| `service/PlaylistLoader` | Turns a `Source` into a `ChannelStore`: parse file, stream URL to a disk cache then parse, or query Xtream. Supersedes stale loads via a generation counter. |
| `storage/Database` | SQLite connection (WAL, small page cache) + ordered migrations in `PRAGMA user_version`. |
| `storage/SourceRepository` | CRUD for sources. |
| `util/StringTable` | Deduplicating string table addressed by `quint16`. |

### Loading a source

```mermaid
sequenceDiagram
    participant QML
    participant Library as Library (ui)
    participant Loader as PlaylistLoader (core)
    participant Pool as QThreadPool
    QML->>Library: selectSource(id)
    Library->>Library: release current ChannelStore
    Library->>Loader: load(source)
    alt M3U URL without cache
        Loader->>Loader: QNetworkReply → QSaveFile (256 KiB read buffer)
    end
    Loader->>Pool: QtConcurrent::run(M3uParser::parse(file))
    Pool-->>Loader: M3uParseResult (shared ChannelStore)
    Loader-->>Library: loaded(id, store, epgUrls)
    Library->>QML: channels model reset (indices only)
```

## UI (`src/ui`)

* **C++ ↔ QML boundary** — `Library` is a `QML_SINGLETON` facade; models are
  `QAbstractListModel`s registered with `QML_ELEMENT`. QML never sees core
  types directly.
* **`ChannelListModel`** holds the shared store plus a `std::vector<quint32>`
  of filtered row indices. Group filtering compares interned ids; text search
  first tries a byte match before allocating a temporary `QString`.
* **QML structure**

  | Folder | Contents |
  |---|---|
  | `qml/theme` | `Theme` singleton — every color, radius, spacing, font, duration |
  | `qml/components` | Reusable controls (`PillButton`, `SegmentedControl`, `SearchField`, `ToggleSwitch`, `ChannelLogo`, `Icon`, …) |
  | `qml/pages` | `HomePage`, `LiveTvPage`, `SettingsPage` |
  | `qml/player` | `VideoPlayer` (Qt Multimedia) |
  | `qml/sheets` | Modal flows (`AddSourceSheet`) |
  | `qml/Session.qml` | UI session state + persisted preferences |

* **Navigation** — `Session.page` drives a `StackView.replace`; pages are
  created on entry and destroyed on exit.
* **Compilation** — QML is compiled ahead of time (`qmlcachegen`/`qmlsc`)
  and linted with `qmllint` (`cmake --build … --target all_qmllint`).

## Threading

| Work | Thread |
|---|---|
| UI, models, SQLite, network I/O callbacks | GUI thread |
| M3U parsing, Xtream JSON → store conversion | `QThreadPool::globalInstance()` via `QtConcurrent::run` |
| Video decoding/rendering | Qt Multimedia internal threads + scene graph render thread |

Results cross threads only as immutable `shared_ptr<const ChannelStore>`.

## Persistence

| What | Where |
|---|---|
| Sources, favorites, history | SQLite `AppDataLocation/iptvx.db` |
| Cached remote playlists | `CacheLocation/playlists/<sourceId>.m3u` |
| Artwork HTTP cache (128 MiB cap) | `CacheLocation/artwork` |
| UI preferences | `QSettings` (`ui/*`) |

Migrations are append-only: never edit a released migration in
`Database.cpp`; add a new entry to `kMigrations`.

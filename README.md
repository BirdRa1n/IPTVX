<div align="center">

<img src="resources/icons/iptvx-256.png" alt="IPTVX icon" width="112">

# IPTVX

**A fast, beautiful and memory‑frugal IPTV player for macOS, Windows and Linux — built with Qt 6 and modern C++.**

[![CI](https://github.com/BirdRa1n/IPTVX/actions/workflows/ci.yml/badge.svg)](https://github.com/BirdRa1n/IPTVX/actions/workflows/ci.yml)
![Qt](https://img.shields.io/badge/Qt-6.9%2B-41CD52?logo=qt&logoColor=white)
![C++](https://img.shields.io/badge/C%2B%2B-20-00599C?logo=cplusplus&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Windows%20%7C%20Linux-lightgrey)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

<img src="docs/screenshots/live-dark.png" alt="IPTVX Live TV in dark mode" width="900">

</div>

> [!IMPORTANT]
> IPTVX is a **player**. It does not provide, sell or bundle any channels,
> playlists or subscriptions. Bring your own M3U playlist or provider account.

---

## ✨ Highlights

|  |  |
|---|---|
| 🎨 **Workspace design** | Graphite surfaces with a vivid accent, compact icon rail with a spring‑animated selection, source switcher, source health cards and fluid transitions — in **dark and light** (or following the system), with four accent presets. |
| 🪟 **Mini player** | Leave Live TV and the channel keeps playing in a draggable picture‑in‑picture window that snaps to the corners. |
| ⌘ **Command palette** | `⌘/Ctrl+K` searches channels and runs commands (navigate, add/refresh sources, switch appearance) without leaving the keyboard. |
| 🪶 **Built to be light** | Channels live in a compact columnar store (≈44 bytes + UTF‑8 text per channel), playlists are parsed as a stream, only one catalog is resident at a time and artwork is cached on disk. See [Memory strategy](docs/MEMORY.md). |
| 📺 **Your sources** | M3U / M3U8 from a URL (cached for offline start) or a local file, and Xtream Codes accounts. Stalker portals are on the [roadmap](docs/ROADMAP.md). |
| ⚡ **Native & fast** | C++20 core, QML compiled ahead of time, playback through Qt Multimedia's FFmpeg backend, heavy work on worker threads. |
| ⌨️ **Keyboard friendly** | Space to play/pause, `M` mute, `F` full screen, arrows for volume, `⌘/Ctrl+N` add a source, `⌘/Ctrl+1/2` switch pages. |
| 🌍 **Localized** | English and Brazilian Portuguese. |

## 📸 Screenshots

| Dashboard — light | Mini player — light |
|---|---|
| <img src="docs/screenshots/dashboard-light.png" alt="Dashboard in light mode"> | <img src="docs/screenshots/mini-player-light.png" alt="Mini player over the dashboard"> |
| **Command palette — dark** | **Add a source — light** |
| <img src="docs/screenshots/command-palette-dark.png" alt="Command palette in dark mode"> | <img src="docs/screenshots/add-source-light.png" alt="Add source sheet in light mode"> |

**[See the full gallery →](docs/SCREENSHOTS.md)**

## 🚀 Getting started

### Requirements

| Tool | Version |
|---|---|
| Qt | **6.9 or newer** with Qt Quick, Quick Controls 2, Multimedia, SQL, Network, Concurrent, Linguist Tools |
| CMake | 3.21+ |
| Compiler | Clang 15+, GCC 12+ or MSVC 2022 (C++20) |
| Generator | Ninja (recommended) |

### Build & run

```bash
# Point CMake at your Qt installation
export CMAKE_PREFIX_PATH="$HOME/Qt/6.12.0/macos"   # e.g. …/gcc_64 on Linux, …\msvc2022_64 on Windows

cmake --preset release
cmake --build --preset release
./build/release/src/app/IPTVX.app/Contents/MacOS/IPTVX   # macOS
./build/release/src/app/IPTVX                            # Linux / Windows
```

Run the tests:

```bash
cmake --preset debug && cmake --build --preset debug
ctest --preset debug
```

Platform notes, packaging and the developer/sandbox mode are covered in
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## 🧭 Project layout

```
IPTVX/
├── src/
│   ├── core/        # GUI-free C++ domain layer (static lib iptvx_core)
│   │   ├── model/   # ChannelStore, Source
│   │   ├── parser/  # Streaming M3U/M3U8 parser
│   │   ├── provider/# Xtream Codes client
│   │   ├── service/ # PlaylistLoader (file / URL cache / Xtream)
│   │   ├── storage/ # SQLite database, migrations, repositories
│   │   └── util/    # StringTable (interning)
│   ├── ui/          # QML module IPTVX.UI (static lib iptvx_ui)
│   │   ├── models/  # QAbstractListModels exposed to QML
│   │   └── qml/     # theme/, shell/, components/, pages/, player/, sheets/
│   └── app/         # Executable: main.cpp + developer tooling
├── tests/           # Qt Test suites + synthetic fixtures
├── i18n/            # Translations (.ts)
├── docs/            # Architecture, memory, design, development, roadmap
├── cmake/           # Shared compiler settings
└── AGENTS.md        # Guide for AI coding agents
```

## 📚 Documentation

| Document | What's inside |
|---|---|
| [Architecture](docs/ARCHITECTURE.md) | Layers, data flow, threading, persistence |
| [Memory strategy](docs/MEMORY.md) | How IPTVX keeps its footprint low, rules for new code |
| [Design system](docs/DESIGN.md) | Workspace tokens (dark & light), components, motion, explored concepts |
| [Development](docs/DEVELOPMENT.md) | Building on each OS, presets, testing, dev mode, i18n |
| [Screenshots](docs/SCREENSHOTS.md) | Gallery of every screen in dark and light |
| [Roadmap](docs/ROADMAP.md) | Feature parity plan with established IPTV players |
| [Contributing](CONTRIBUTING.md) | Workflow, commit style, code style |
| [AGENTS.md](AGENTS.md) | Rules and entry points for AI coding agents |

## 🙏 Acknowledgements

Feature scope was inspired by the open-source
[IPTVnator](https://github.com/4gray/iptvnator) project. IPTVX is an
independent implementation in Qt/C++ and shares no code or assets with it.

## 📄 License

[MIT](LICENSE) © Dário Jr

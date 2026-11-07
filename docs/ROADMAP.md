# Roadmap

Feature scope is modeled on mature open-source IPTV players (notably
IPTVnator). ✅ done · 🚧 in progress · ⏳ planned.

## Sources

| Feature | Status |
|---|---|
| M3U/M3U8 from URL (disk-cached, offline start) | ✅ |
| M3U/M3U8 from local file | ✅ |
| `#EXTINF` attributes, `#EXTGRP`, `#EXTVLCOPT`, pipe headers, `radio`, `catchup-days` | ✅ |
| Per-source custom User-Agent | ✅ (download) / ⏳ (playback headers) |
| Xtream Codes — authentication + live channels | ✅ |
| Xtream Codes — VOD movies & series (seasons, episodes, info) | ⏳ |
| Stalker / Ministra portals (MAC handshake, ITV, VOD, series) | ⏳ |
| Refresh on startup / scheduled refresh | ⏳ |
| Edit source, import/export backup | ⏳ |
| Credentials in the OS keychain | ⏳ |

## Live TV & EPG

| Feature | Status |
|---|---|
| Group filtering, search, channel numbers | ✅ |
| Previous/next channel, keyboard controls | ✅ |
| XMLTV EPG (streaming parser, time-window cache) | ⏳ |
| Now/next on rows, EPG timeline grid (Nebula concept) | ⏳ |
| Catch-up / timeshift | ⏳ |
| Radio player for `radio="true"` | ⏳ |

## Library

| Feature | Status |
|---|---|
| Favorites (schema ready) | ⏳ |
| Watch history & resume positions (schema ready) | ⏳ |
| Continue watching rail | 🚧 (last channel) |
| Global search across sources | ⏳ |
| Parental lock (PIN per group) | ⏳ |
| TMDB metadata (opt-in, user API key) | ⏳ |
| Downloads for VOD | ⏳ |

## Playback

| Feature | Status |
|---|---|
| Qt Multimedia (FFmpeg) player, mute/volume, full screen | ✅ |
| Audio / subtitle track selection | ⏳ |
| Per-stream HTTP headers (User-Agent, Referer) | ⏳ |
| Optional libmpv backend | ⏳ |
| External player (mpv / VLC / IINA) | ⏳ |
| In-app mini player (picture-in-picture) | ✅ |
| OS-level picture-in-picture window | ⏳ |

## Experience

| Feature | Status |
|---|---|
| Workspace design system, light/dark/system, accent presets | ✅ |
| Reduce motion | ✅ |
| English, Brazilian Portuguese | ✅ |
| Command palette (⌘/Ctrl+K) | ✅ (channels + commands) |
| Alternative themes from the concept canvas | ⏳ |
| More languages | ⏳ |

## Performance & memory

| Item | Status |
|---|---|
| Columnar `ChannelStore`, interning, streaming parser | ✅ |
| One resident catalog, recycled delegates, disk artwork cache | ✅ |
| Memory-mapped catalog cache (instant start for huge lists) | ⏳ |
| SQLite FTS5 index for search over 100k+ entries | ⏳ |
| Benchmarks in CI (parse time, footprint per 100k channels) | ⏳ |

## Distribution

| Item | Status |
|---|---|
| CI build + tests on macOS, Windows, Linux | ✅ |
| App icon (icns / ico / hicolor + .desktop) | ✅ |
| Signed macOS DMG, Windows installer, Linux AppImage | ⏳ |

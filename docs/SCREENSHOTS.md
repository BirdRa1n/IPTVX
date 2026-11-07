# Screenshots

[Back to README](../README.md)

Every screen ships in **dark and light** appearances. All content below is
synthetic demo data ([`docs/demo/demo.m3u`](demo/demo.m3u)) — IPTVX does not
provide channels.

## Dashboard

Greeting, continue watching, groups and source health.

| Dark | Light |
|---|---|
| <img src="screenshots/dashboard-dark.png" alt="Dashboard, dark appearance"> | <img src="screenshots/dashboard-light.png" alt="Dashboard, light appearance"> |

## Live TV

Channel filter, group chips and a recycled channel list beside the player.
Radio and still-connecting streams show the channel identity; the up-next
ribbon will host the programme guide.

| Dark | Light |
|---|---|
| <img src="screenshots/live-dark.png" alt="Live TV playing a channel, dark"> | <img src="screenshots/live-light.png" alt="Live TV playing a channel, light"> |

## Mini player

Leave Live TV and the channel keeps playing in a floating, draggable
picture-in-picture window that snaps to the nearest corner.

| Light — over the dashboard | Dark — over settings |
|---|---|
| <img src="screenshots/mini-player-light.png" alt="Mini player over the dashboard, light"> | <img src="screenshots/mini-player-dark.png" alt="Mini player over settings, dark"> |

## Command palette and adding a source

`⌘K` / `Ctrl+K` searches channels and runs commands; sources are added from a
sheet (M3U URL, M3U file or Xtream Codes).

| Command palette — dark | Add a source — light |
|---|---|
| <img src="screenshots/command-palette-dark.png" alt="Command palette searching channels, dark"> | <img src="screenshots/add-source-light.png" alt="Add source sheet, light"> |

## Settings

Appearance (system / light / dark), accent presets, reduced motion, sources
and the memory used by the channel catalog.

<img src="screenshots/settings-dark.png" alt="Settings, dark appearance">

---

### Regenerating the gallery

```bash
cmake --preset debug && cmake --build --preset debug
tools/screenshots.sh
```

On macOS the captures include the native window frame (traffic lights,
rounded corners, shadow) through `screencapture -l`; give your terminal the
**Screen Recording** permission for that. Without it the app composites an
equivalent frame at the measured position of the window controls. See
[DEVELOPMENT.md](DEVELOPMENT.md#developer-mode-sandbox-seeding-screenshots) for
the individual `IPTVX_*` switches.

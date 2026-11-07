# Design system

IPTVX ships the **Aurora** design system — calm, translucent and
SwiftUI-inspired. Two further concepts (**Cinema** and **Nebula**) were
explored and remain candidates for alternative themes.

## Concepts

| Concept | Personality | Signature elements | Status |
|---|---|---|---|
| **A · Aurora** | SwiftUI / macOS — calm, airy, native | Source-list sidebar with accent selection pill, large titles, segmented pickers, inset grouped forms, glass player capsule | ✅ Implemented |
| **B · Cinema** | Immersive, poster-first, dark | Full-bleed backdrop with gradient scrims, display type (Space Grotesk), gold accent, cinematic player overlay with audio/subtitle panel | 💡 Concept |
| **C · Nebula** | Dense, productive, keyboard-first | Icon rail, EPG timeline grid, command palette (⌘K), teal accent on deep navy | 💡 Concept |

The concept boards (Aurora Home & Live TV, Cinema Detail & Player, Nebula
Guide & Add Source) live in the project's design canvas.

## Tokens (`src/ui/qml/theme/Theme.qml`)

All visual values come from the `Theme` singleton. **Never hard-code a color,
radius, spacing, font or duration in a component.**

### Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | `#0A64D6` (user selectable) | same | Selection, primary actions, progress |
| `window` | `#FFFFFF` | `#1C1C1E` | Content background |
| `sidebar` | `#F2F2F5` | `#232326` | Sidebar / secondary panes |
| `card` / `cardHover` | `#F5F5F8` / `#EDEDF2` | `#2A2A2E` / `#323237` | Cards, form groups |
| `field` | `#E4E4EA` | `#2F2F34` | Inputs, segmented track, chips |
| `textPrimary` / `textSecondary` / `textTertiary` | `#1C1C1E` / `#5E5E66` / `#6C6C74` | `#F5F5F7` / `#A1A1A8` / `#7C7C84` | Text hierarchy (all ≥ 4.5:1 on their surfaces) |
| `material` | 80 % white | 82 % graphite | Floating "glass" bars |
| `live`, `success`, `danger` | system red / green / red | | Status |

Accent presets: blue `#0A64D6`, indigo `#5E3FD1`, orange `#C2410C`, green
`#0F7B5F`, raspberry `#B4235A`.

### Shape & spacing

* Radii: `radiusSmall 8`, `radiusMedium 12`, `radiusLarge 18`, `radiusXL 22`;
  capsules use `height / 2`.
* Spacing scale: `4 · 8 · 12 · 16 · 20 · 28 · 36` (`space1` … `space7`).
* Control height 34, sidebar width 248, touch/click targets ≥ 28 px.

### Typography

The platform font (SF Pro on macOS, Segoe UI on Windows, the desktop font on
Linux) — no font files are shipped.

| Style | Size / weight |
|---|---|
| `largeTitle` | 34 / ExtraBold |
| `title` | 28 / ExtraBold |
| `title2` | 20 / Bold |
| `headline` | 15 / DemiBold |
| `body` | 14 |
| `callout` | 13 |
| `caption` | 12 |
| `sectionLabel` | 11 / DemiBold, uppercase |

### Motion

| Token | Value | Typical use |
|---|---|---|
| `durationFast` | 140 ms | Hover, press, color |
| `durationMedium` | 260 ms | Panels, overlay fades, page enter |
| `durationSlow` | 420 ms | Sheets, empty-state entrance |
| Springs | `SpringAnimation { spring: 4–5; damping: 0.35–0.4 }` | Selection pill, segmented thumb, switch knob |
| `Easing.OutBack` (`springOvershoot` 1.15) | | Sheet scale-in, toast |

`Theme.reduceMotion` (Settings › Reduce motion) collapses every duration to
0 and stops decorative loops.

## Components

| Component | Notes |
|---|---|
| `SidebarItem` | Icon + label + trailing text/dot; `drawsSelection: false` when a shared pill is drawn behind |
| `PillButton` | Capsule; `prominent` (filled) or tinted; press scale 0.96 |
| `SegmentedControl` | Spring-animated thumb |
| `SearchField` | Magnifier, clear button, 180 ms `debounced` signal |
| `ToggleSwitch` | iOS-style switch |
| `ChannelLogo` | Artwork at display size with monogram fallback tinted from the name |
| `ChannelRow` | Number · logo · name · group, current-row indicator |
| `EmptyState` | Icon badge, title, message, action; fade + rise entrance |
| `Icon` | Vector stroke icons (Qt Quick Shapes); add new paths to `paths` |

## Accessibility

* Every icon-only button sets `Accessible.name`.
* Focus rings (`visualFocus`) use the accent color.
* Text contrast ≥ 4.5:1 in both appearances.
* Keyboard: see README › Highlights.

## Adding a theme

1. Copy the token block in `Theme.qml` into a new palette and switch on a
   `Theme.style` property.
2. Do not fork components; if a concept needs a different structure (e.g.
   Nebula's icon rail), add a new component and choose it in `Main.qml`.

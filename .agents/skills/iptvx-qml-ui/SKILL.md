---
name: iptvx-qml-ui
description: Use when creating or changing IPTVX screens, QML components, animations or theme tokens (Aurora design system).
---

# IPTVX QML UI work

## Before writing QML

- Read `docs/DESIGN.md` (tokens, components, motion).
- Reuse components in `src/ui/qml/components/` before creating new ones.

## Rules

- Style only with `Theme.*` tokens. Durations: `Theme.durationFast/Medium/Slow`
  (they become 0 with reduce motion). Springs for selection indicators.
- Never declare a property named `on<Something>` (it becomes a signal
  handler and breaks the type).
- Delegates: `pragma ComponentBehavior: Bound`, `required property` per role,
  give the delegate an `id` and reference roles through it.
- Lists: `ListView` with `reuseItems: true`; images with `asynchronous: true`
  and `sourceSize` set to the displayed size × `Screen.devicePixelRatio`.
- Items inside Layouts use `Layout.preferredWidth/Height`, not `width/height`.
- New file → add to `QML_FILES` in `src/ui/CMakeLists.txt`; singleton → also
  `QT_QML_SINGLETON_TYPE`.
- Strings via `qsTr()`; then `--target update_translations` and translate
  `i18n/iptvx_pt_BR.ts`.

## Verify

```bash
cmake --build --preset debug && cmake --build --preset debug --target all_qmllint
for page in home live settings; do
  IPTVX_SEED_PLAYLIST=tests/data/sample.m3u IPTVX_PAGE=$page IPTVX_APPEARANCE=dark \
  IPTVX_SCREENSHOT=/tmp/iptvx-$page.png ./build/debug/src/app/IPTVX.app/Contents/MacOS/IPTVX
done
```

Open the PNGs and check both appearances (`IPTVX_APPEARANCE=light|dark`).
Watch stderr for `qrc:/…qml` warnings — they must be empty.

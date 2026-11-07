pragma Singleton

import QtQuick

// Aurora design tokens (SwiftUI-inspired).
//
// Every color, radius, spacing step, font size and motion curve used by the
// UI comes from here. Components must never hard-code these values, so a
// different design concept (see docs/DESIGN.md) is a change to this file.
QtObject {
    id: theme

    // ---- Appearance ------------------------------------------------------
    // "system" follows the OS, otherwise "light" / "dark".
    property string appearance: "system"
    readonly property bool dark: appearance === "dark"
        || (appearance === "system" && Application.styleHints.colorScheme === Qt.ColorScheme.Dark)

    property color accent: "#0A64D6"
    readonly property color accentPressed: Qt.darker(accent, 1.15)
    readonly property color accentSoft: Qt.alpha(accent, dark ? 0.22 : 0.12)
    readonly property color onAccent: "#FFFFFF"

    // ---- Surfaces --------------------------------------------------------
    readonly property color window: dark ? "#1C1C1E" : "#FFFFFF"
    readonly property color sidebar: dark ? "#232326" : "#F2F2F5"
    readonly property color sidebarBorder: dark ? "#2F2F33" : "#E3E3E8"
    readonly property color card: dark ? "#2A2A2E" : "#F5F5F8"
    readonly property color cardHover: dark ? "#323237" : "#EDEDF2"
    readonly property color field: dark ? "#2F2F34" : "#E4E4EA"
    readonly property color separator: dark ? "#38383D" : "#E1E1E7"
    readonly property color material: dark ? Qt.rgba(0.17, 0.17, 0.19, 0.82) : Qt.rgba(0.96, 0.96, 0.98, 0.80)
    readonly property color scrim: Qt.rgba(0, 0, 0, dark ? 0.55 : 0.32)
    readonly property color video: "#0E1520"

    // ---- Text ------------------------------------------------------------
    readonly property color textPrimary: dark ? "#F5F5F7" : "#1C1C1E"
    readonly property color textSecondary: dark ? "#A1A1A8" : "#5E5E66"
    readonly property color textTertiary: dark ? "#7C7C84" : "#6C6C74"
    readonly property color live: "#FF453A"
    readonly property color success: "#28A745"
    readonly property color danger: dark ? "#FF6961" : "#D70015"

    // ---- Shape & spacing -------------------------------------------------
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusXL: 22

    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 28
    readonly property int space7: 36

    readonly property int sidebarWidth: 248
    readonly property int controlHeight: 34

    // ---- Typography ------------------------------------------------------
    // The platform font is used on purpose (SF Pro on macOS, Segoe UI on
    // Windows, the desktop font on Linux): no font files are shipped/loaded.
    readonly property font largeTitle: Qt.font({ pixelSize: 34, weight: Font.ExtraBold, letterSpacing: -0.6 })
    readonly property font title: Qt.font({ pixelSize: 28, weight: Font.ExtraBold, letterSpacing: -0.4 })
    readonly property font title2: Qt.font({ pixelSize: 20, weight: Font.Bold })
    readonly property font headline: Qt.font({ pixelSize: 15, weight: Font.DemiBold })
    readonly property font body: Qt.font({ pixelSize: 14 })
    readonly property font callout: Qt.font({ pixelSize: 13 })
    readonly property font caption: Qt.font({ pixelSize: 12 })
    readonly property font sectionLabel: Qt.font({ pixelSize: 11, weight: Font.DemiBold, letterSpacing: 0.3 })

    // ---- Motion ----------------------------------------------------------
    // Short, spring-like motion. Respect "reduce motion" by setting
    // `reduceMotion` (wired to settings later).
    property bool reduceMotion: false
    readonly property int durationFast: reduceMotion ? 0 : 140
    readonly property int durationMedium: reduceMotion ? 0 : 260
    readonly property int durationSlow: reduceMotion ? 0 : 420
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEmphasized: Easing.OutBack
    readonly property real springOvershoot: 1.15

    function monogram(name) {
        const words = String(name).replace(/[^\p{L}\p{N} ]/gu, " ").trim().split(/\s+/)
        if (words.length === 0 || words[0] === "")
            return "TV"
        if (words.length === 1)
            return words[0].substring(0, 2).toUpperCase()
        return (words[0][0] + words[1][0]).toUpperCase()
    }

    // Stable, pleasant tint for a channel monogram derived from its name.
    function tint(name) {
        const palette = ["#B4372F", "#1F6F43", "#2B5C9A", "#8A4FBF", "#7A4B1F",
                         "#A3326E", "#2E7A80", "#9A5B12", "#4B5A9A", "#5E7A2E"]
        let h = 0
        const s = String(name)
        for (let i = 0; i < s.length; ++i)
            h = (h * 31 + s.charCodeAt(i)) >>> 0
        return palette[h % palette.length]
    }
}

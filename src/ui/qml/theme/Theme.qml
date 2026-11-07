pragma Singleton

import QtQuick

// "Workspace" design tokens — graphite surfaces with a vivid accent,
// in dark and light appearances.
//
// Every color, radius, spacing step, font size and motion curve used by the
// UI comes from here. Components must never hard-code these values.
QtObject {
    id: theme

    // ---- Appearance ------------------------------------------------------
    // "system" follows the OS, otherwise "light" / "dark".
    property string appearance: "system"
    readonly property bool dark: appearance === "dark"
        || (appearance === "system" && Application.styleHints.colorScheme === Qt.ColorScheme.Dark)

    // Accent presets. `accent` is a *fill* color (always paired with dark
    // `accentForeground` text); `accentText` is the readable variant used
    // for text, icons and thin indicators on the current background.
    readonly property var accentPresets: [
        { fill: "#C6F432", lightText: "#3F6212" },   // lime (default)
        { fill: "#7DD3FC", lightText: "#075985" },   // sky
        { fill: "#FDA4AF", lightText: "#9F1239" },   // rose
        { fill: "#FCD34D", lightText: "#92400E" }    // amber
    ]
    property color accent: "#C6F432"
    readonly property color accentText: {
        if (dark)
            return accent
        for (const p of accentPresets)
            if (Qt.colorEqual(p.fill, accent))
                return p.lightText
        return Qt.darker(accent, 2.4)
    }
    readonly property color accentForeground: "#141414"
    readonly property color accentSoft: Qt.alpha(dark ? accent : accentText, dark ? 0.12 : 0.12)

    // ---- Surfaces --------------------------------------------------------
    readonly property color bg: dark ? "#141414" : "#F7F7F5"
    readonly property color surface: dark ? "#1C1C1C" : "#FFFFFF"
    readonly property color raised: dark ? "#242424" : "#FFFFFF"
    readonly property color hover: dark ? "#202020" : "#EFEFEC"
    readonly property color chip: dark ? "#242424" : "#EBEBE7"
    readonly property color cell: dark ? "#1E1E1E" : "#EFEFEC"
    readonly property color track: dark ? "#2C2C2C" : "#E4E4E0"
    readonly property color divider: dark ? "#262626" : "#E4E4E0"
    readonly property color border: dark ? "#2E2E2E" : "#E1E1DC"
    readonly property color borderStrong: dark ? "#3A3A3A" : "#CFCFC9"
    readonly property color scrim: dark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0.08, 0.08, 0.08, 0.28)
    readonly property color overlay: Qt.rgba(0.08, 0.08, 0.08, 0.78) // on top of video
    readonly property color video: "#0A0A0A"

    // ---- Text ------------------------------------------------------------
    readonly property color textPrimary: dark ? "#ECECEA" : "#141414"
    readonly property color textSecondary: dark ? "#A8A8A4" : "#55554F"
    readonly property color textTertiary: dark ? "#9A9A96" : "#66665F"
    readonly property color chipText: dark ? "#D6D6D2" : "#2A2A28"
    readonly property color videoText: "#ECECEA"
    readonly property color videoTextSecondary: "#B4B4B0"

    readonly property color live: "#FF453A"
    readonly property color success: "#2FA84F"
    readonly property color warning: "#D99A1E"
    readonly property color danger: dark ? "#FF6B6B" : "#C4141B"

    // ---- Shape & spacing -------------------------------------------------
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14
    readonly property int radiusXL: 16

    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 26
    readonly property int space7: 32

    readonly property int railWidth: 64
    readonly property int listPaneWidth: 330
    readonly property int controlHeight: 38

    // ---- Typography ------------------------------------------------------
    // The platform font is used on purpose (SF Pro / Segoe UI / desktop
    // font): no font files are shipped or loaded.
    readonly property font largeTitle: Qt.font({ pixelSize: 28, weight: Font.ExtraBold, letterSpacing: -0.3 })
    readonly property font title: Qt.font({ pixelSize: 22, weight: Font.ExtraBold })
    readonly property font title2: Qt.font({ pixelSize: 17, weight: Font.ExtraBold })
    readonly property font headline: Qt.font({ pixelSize: 14, weight: Font.Bold })
    readonly property font body: Qt.font({ pixelSize: 14 })
    readonly property font callout: Qt.font({ pixelSize: 13 })
    readonly property font caption: Qt.font({ pixelSize: 12 })
    readonly property font sectionLabel: Qt.font({ pixelSize: 11, weight: Font.Bold, letterSpacing: 0.6 })

    // ---- Motion ----------------------------------------------------------
    property bool reduceMotion: false
    readonly property int durationFast: reduceMotion ? 0 : 120
    readonly property int durationMedium: reduceMotion ? 0 : 220
    readonly property int durationSlow: reduceMotion ? 0 : 360
    readonly property real springOvershoot: 1.2

    function monogram(name) {
        const words = String(name).replace(/[^\p{L}\p{N} ]/gu, " ").trim().split(/\s+/)
        if (words.length === 0 || words[0] === "")
            return "TV"
        if (words.length === 1)
            return words[0].substring(0, 2).toUpperCase()
        return (words[0][0] + words[1][0]).toUpperCase()
    }

    // Stable tint for a channel monogram derived from its name (all pass
    // 4.5:1 with white text).
    function tint(name) {
        const palette = ["#B4372F", "#1F6F43", "#2B5C9A", "#8A4FBF", "#7A4B1F",
                         "#A3326E", "#2E7A80", "#9A5B12", "#4B5A9A", "#5E7A2E"]
        let h = 0
        const s = String(name)
        for (let i = 0; i < s.length; ++i)
            h = (h * 31 + s.charCodeAt(i)) >>> 0
        return palette[h % palette.length]
    }

    function greeting() {
        const h = new Date().getHours()
        return h < 12 ? qsTr("Good morning") : h < 18 ? qsTr("Good afternoon") : qsTr("Good evening")
    }
}

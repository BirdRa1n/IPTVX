pragma Singleton

import QtQuick
import QtCore

// UI session state shared by pages: navigation, now playing and the
// persisted appearance preferences.
QtObject {
    id: session

    // "home" | "live" | "settings"
    property string page: "home"

    // Row in Library.channels of the channel being played (-1 = none) and a
    // snapshot of its data, so the Home page can offer "continue watching".
    property int playingRow: -1
    property var nowPlaying: null

    function play(row) {
        const item = Library.channels.get(row)
        if (!item || !item.url)
            return
        playingRow = row
        nowPlaying = item
        lastChannelName = item.name
        lastChannelUrl = item.url
    }

    function step(delta) {
        const count = Library.channels.count
        if (count === 0)
            return
        const next = playingRow < 0 ? 0 : (playingRow + delta + count) % count
        play(next)
    }

    // Persisted preferences (QSettings, "ui" group).
    property string appearance: "system"
    property string accent: "#0A64D6"
    property bool reduceMotion: false
    property string lastChannelName
    property string lastChannelUrl

    property Settings store: Settings {
        category: "ui"
        property alias appearance: session.appearance
        property alias accent: session.accent
        property alias reduceMotion: session.reduceMotion
        property alias lastChannelName: session.lastChannelName
        property alias lastChannelUrl: session.lastChannelUrl
    }

    Component.onCompleted: {
        Theme.appearance = Qt.binding(() => session.appearance)
        Theme.accent = Qt.binding(() => session.accent)
        Theme.reduceMotion = Qt.binding(() => session.reduceMotion)
    }
}

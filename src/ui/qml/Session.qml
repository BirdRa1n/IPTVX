pragma Singleton

import QtQuick
import QtCore
import QtMultimedia

// UI session state shared by pages: navigation, playback and the persisted
// appearance preferences.
QtObject {
    id: session

    // "home" (dashboard) | "live" | "settings"
    property string page: "home"

    // Row in Library.channels of the channel being played (-1 = none) and a
    // snapshot of its data, so the Home page can offer "continue watching".
    property int playingRow: -1
    property var nowPlaying: null

    // The one media player of the app. It outlives pages, so playback keeps
    // going while the user browses; the Live TV player and the mini player
    // only borrow its video output (one decoder, one set of buffers).
    property MediaPlayer player: MediaPlayer {
        audioOutput: AudioOutput { volume: 0.9 }
    }
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState

    // Set when the user closes the mini player; cleared on the next play().
    property bool miniPlayerDismissed: false

    function play(row) {
        const item = Library.channels.get(row)
        if (!item || !item.url)
            return
        playingRow = row
        nowPlaying = item
        lastChannelName = item.name
        lastChannelUrl = item.url
        miniPlayerDismissed = false
        // Assign the source right before play(): no binding to race with.
        player.stop()
        player.source = item.url
        player.play()
    }

    function togglePlay() {
        if (isPlaying)
            player.pause()
        else if (player.source.toString().length > 0)
            player.play()
    }

    // Stops playback and forgets the current channel (mini player close).
    function stop() {
        player.stop()
        player.source = ""
        nowPlaying = null
        playingRow = -1
    }

    // Plays the channel with catalog number `number` (1-based), clearing
    // list filters so the row and the catalog index coincide.
    function playNumber(number) {
        Library.channels.searchText = ""
        Library.channels.group = ""
        play(number - 1)
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
    property string accent: "#C6F432"
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
        // Accents saved by older designs are not Workspace presets: reset.
        if (!Theme.accentPresets.some(p => p.fill.toLowerCase() === accent.toLowerCase()))
            accent = Theme.accentPresets[0].fill
        Theme.appearance = Qt.binding(() => session.appearance)
        Theme.accent = Qt.binding(() => session.accent)
        Theme.reduceMotion = Qt.binding(() => session.reduceMotion)
    }
}

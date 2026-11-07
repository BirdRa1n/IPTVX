import QtQuick
import QtQuick.Controls.Basic
import QtMultimedia
import IPTVX.UI

// Video surface with a floating "glass" control bar that auto-hides.
//
// Playback uses Qt Multimedia (FFmpeg backend on every desktop platform).
// Decoding happens on Qt's media threads; frames go straight to the scene
// graph without extra copies.
Rectangle {
    id: root

    property url source
    property string title
    property string subtitle
    property bool live: true
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState
    readonly property bool loading: player.mediaStatus === MediaPlayer.LoadingMedia
                                    || player.mediaStatus === MediaPlayer.BufferingMedia
                                    || player.mediaStatus === MediaPlayer.StalledMedia

    signal previousRequested()
    signal nextRequested()
    signal fullScreenRequested()

    color: Theme.video
    radius: Theme.radiusLarge
    clip: true

    function togglePlay() { root.playing ? player.pause() : player.play() }

    onSourceChanged: {
        player.stop()
        if (source.toString().length > 0)
            player.play()
    }

    MediaPlayer {
        id: player
        source: root.source
        videoOutput: videoSurface
        audioOutput: AudioOutput { id: audio; volume: 0.9 }
    }

    VideoOutput {
        id: videoSurface
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    // ---- States ----------------------------------------------------------
    Label {
        anchors.centerIn: parent
        visible: root.source.toString().length === 0
        text: qsTr("Choose a channel to start watching")
        color: "#6F829B"
        font: Theme.body
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: root.loading
        visible: running
        palette.dark: "#FFFFFF"
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - 64
        visible: player.error !== MediaPlayer.NoError
        text: qsTr("Unable to play this stream.\n%1").arg(player.errorString)
        color: "#FFFFFF"
        font: Theme.body
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    // ---- Overlay ----------------------------------------------------------
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPositionChanged: { overlay.shown = true; hideTimer.restart() }
        onDoubleClicked: root.fullScreenRequested()
        onClicked: { overlay.shown = true; hideTimer.restart() }
    }

    Timer {
        id: hideTimer
        interval: 2600
        onTriggered: overlay.shown = !root.playing
    }

    Item {
        id: overlay
        property bool shown: true
        anchors.fill: parent
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }

        // Live badge
        Rectangle {
            visible: root.title.length > 0
            x: 16; y: 16
            height: 28
            width: badgeRow.implicitWidth + 20
            radius: 10
            color: Qt.rgba(0.08, 0.08, 0.09, 0.55)
            Row {
                id: badgeRow
                anchors.centerIn: parent
                spacing: 8
                Rectangle {
                    visible: root.live
                    width: 8; height: 8; radius: 4
                    color: Theme.live
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.playing && !Theme.reduceMotion
                        NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                    }
                }
                Label {
                    text: (root.live ? qsTr("LIVE") + " · " : "") + root.title
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }

        // Floating control capsule
        Rectangle {
            id: bar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: overlay.shown ? 18 : 6
            Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutBack } }
            height: 56
            width: controls.implicitWidth + 40
            radius: 28
            color: Theme.material
            border.width: 0.5
            border.color: Qt.rgba(1, 1, 1, Theme.dark ? 0.08 : 0.5)

            Row {
                id: controls
                anchors.centerIn: parent
                spacing: 16

                component BarButton: AbstractButton {
                    id: barButton
                    property string iconName
                    width: 32; height: 32
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    contentItem: Icon { name: barButton.iconName; color: Theme.textPrimary; filled: barButton.iconName !== "fullscreen" && barButton.iconName !== "volume" && barButton.iconName !== "mute" }
                    scale: pressed ? 0.88 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
                }

                BarButton { iconName: "prev"; Accessible.name: qsTr("Previous channel"); onClicked: root.previousRequested() }
                AbstractButton {
                    width: 42; height: 42
                    anchors.verticalCenter: parent.verticalCenter
                    Accessible.name: root.playing ? qsTr("Pause") : qsTr("Play")
                    onClicked: root.togglePlay()
                    background: Rectangle { radius: 21; color: Theme.textPrimary }
                    contentItem: Item {
                        Icon {
                            anchors.centerIn: parent
                            width: 17; height: 17
                            name: root.playing ? "pause" : "play"
                            filled: true
                            color: Theme.window
                        }
                    }
                    scale: pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
                }
                BarButton { iconName: "next"; Accessible.name: qsTr("Next channel"); onClicked: root.nextRequested() }
                Rectangle { width: 1; height: 22; color: Theme.separator; anchors.verticalCenter: parent.verticalCenter }
                BarButton {
                    iconName: audio.muted ? "mute" : "volume"
                    Accessible.name: audio.muted ? qsTr("Unmute") : qsTr("Mute")
                    onClicked: audio.muted = !audio.muted
                }
                BarButton { iconName: "fullscreen"; Accessible.name: qsTr("Full screen"); onClicked: root.fullScreenRequested() }
            }
        }
    }

    // ---- Keyboard ---------------------------------------------------------
    focus: true
    Keys.onSpacePressed: root.togglePlay()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_M) { audio.muted = !audio.muted; event.accepted = true }
        else if (event.key === Qt.Key_F) { root.fullScreenRequested(); event.accepted = true }
        else if (event.key === Qt.Key_Up) { audio.volume = Math.min(1, audio.volume + 0.05); event.accepted = true }
        else if (event.key === Qt.Key_Down) { audio.volume = Math.max(0, audio.volume - 0.05); event.accepted = true }
    }
}

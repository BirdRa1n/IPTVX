import QtQuick
import QtQuick.Controls.Basic
import QtMultimedia
import IPTVX.UI

// Video surface with an inline control bar that auto-hides.
//
// Playback uses Qt Multimedia (FFmpeg backend on every desktop platform).
// Decoding happens on Qt's media threads; frames go straight to the scene
// graph without extra copies. The video area is always dark, in both
// appearances, so its overlay uses the fixed on-video colors.
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

    // Autoplay: the media source is assigned imperatively, right before
    // play(), so playback never starts on a stale URL (a binding plus an
    // onSourceChanged handler would race). Also covers a player created with
    // a channel already selected (e.g. opened from the dashboard or ⌘K).
    function load() {
        player.stop()
        player.source = root.source
        if (root.source.toString().length > 0)
            player.play()
    }
    onSourceChanged: load()
    Component.onCompleted: load()

    MediaPlayer {
        id: player
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
        color: Theme.videoTextSecondary
        font: Theme.body
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: root.loading
        visible: running
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - 64
        visible: player.error !== MediaPlayer.NoError
        text: qsTr("Unable to play this stream.\n%1").arg(player.errorString)
        color: Theme.videoText
        font: Theme.body
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    // ---- Overlay ----------------------------------------------------------
    MouseArea {
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

        Rectangle {
            id: bar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 14
            anchors.bottomMargin: overlay.shown ? 14 : 4
            Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }
            height: 50
            radius: Theme.radiusLarge - 2
            color: Theme.overlay

            component BarButton: AbstractButton {
                id: barButton
                property string iconName
                property bool filledIcon: true
                width: 32; height: 32
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                hoverEnabled: true
                background: Rectangle { radius: 8; color: barButton.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent" }
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        width: 17; height: 17
                        name: barButton.iconName
                        filled: barButton.filledIcon
                        color: Theme.videoText
                    }
                }
                scale: pressed ? 0.9 : 1
                Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                AbstractButton {
                    width: 34; height: 34
                    anchors.verticalCenter: parent.verticalCenter
                    Accessible.name: root.playing ? qsTr("Pause") : qsTr("Play")
                    onClicked: root.togglePlay()
                    background: Rectangle { radius: 17; color: Theme.accent }
                    contentItem: Item {
                        Icon {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            name: root.playing ? "pause" : "play"
                            filled: true
                            color: Theme.accentForeground
                        }
                    }
                    scale: pressed ? 0.9 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
                }
                BarButton { iconName: "prev"; Accessible.name: qsTr("Previous channel"); onClicked: root.previousRequested() }
                BarButton { iconName: "next"; Accessible.name: qsTr("Next channel"); onClicked: root.nextRequested() }

                Rectangle {
                    visible: root.live && root.title.length > 0
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
                    text: root.title
                    font: Theme.headline
                    color: Theme.videoText
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: root.subtitle
                    font: Theme.caption
                    color: Theme.videoTextSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                BarButton {
                    iconName: audio.muted ? "mute" : "volume"
                    filledIcon: false
                    Accessible.name: audio.muted ? qsTr("Unmute") : qsTr("Mute")
                    onClicked: audio.muted = !audio.muted
                }
                BarButton {
                    iconName: "fullscreen"
                    filledIcon: false
                    Accessible.name: qsTr("Full screen")
                    onClicked: root.fullScreenRequested()
                }
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

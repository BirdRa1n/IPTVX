import QtQuick
import QtQuick.Controls.Basic
import QtMultimedia
import IPTVX.UI

// Floating in-app picture-in-picture. Appears when a channel is playing and
// the user leaves Live TV; playback continues uninterrupted because it lives
// in Session.player — this view only borrows the video output.
//
// Drag it anywhere: on release it springs to the nearest corner of
// `bounds`. Click the video to return to Live TV.
Item {
    id: root

    // Area (in parent coordinates) the mini player may occupy.
    property rect bounds: Qt.rect(0, 0, parent ? parent.width : 0, parent ? parent.height : 0)
    property bool wanted: false            // set by Main: should be on screen
    readonly property bool shown: wanted && Session.nowPlaying !== null && !Session.miniPlayerDismissed

    // 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right
    property int corner: 3
    readonly property real margin: 16

    width: 336
    height: 189
    z: 50

    function cornerX(c) { return (c % 2 === 0) ? bounds.x + margin : bounds.x + bounds.width - width - margin }
    function cornerY(c) { return (c < 2) ? bounds.y + margin : bounds.y + bounds.height - height - margin }

    x: cornerX(corner)
    y: cornerY(corner)
    Behavior on x { enabled: !drag.active; SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
    Behavior on y { enabled: !drag.active; SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }

    // Entrance / exit
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.88
    visible: opacity > 0.01
    transformOrigin: corner === 0 ? Item.TopLeft : corner === 1 ? Item.TopRight
                   : corner === 2 ? Item.BottomLeft : Item.BottomRight
    Behavior on opacity { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershoot } }

    onShownChanged: if (shown) Session.player.videoOutput = surface

    // Soft shadow (stacked translucent rects: no offscreen layer, so no
    // extra GPU memory while video frames update).
    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            anchors.fill: parent
            anchors.margins: -(index + 1) * 3
            anchors.topMargin: -(index + 1) * 2
            anchors.bottomMargin: -(index + 1) * 5
            radius: Theme.radiusLarge + (index + 1) * 3
            color: "transparent"
            border.width: 3
            border.color: Qt.rgba(0, 0, 0, (Theme.dark ? 0.16 : 0.07) / (index + 1))
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.video
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        VideoOutput {
            id: surface
            anchors.fill: parent
            anchors.margins: 1
            fillMode: VideoOutput.PreserveAspectCrop
        }

        // Audio-only streams (radio) and streams still connecting have no
        // picture: show the channel identity instead of a black box.
        ChannelLogo {
            anchors.centerIn: parent
            width: 56; height: 56
            radius: Theme.radiusLarge
            visible: !Session.player.hasVideo
            name: Session.nowPlaying ? Session.nowPlaying.name : ""
            source: Session.nowPlaying ? Session.nowPlaying.logo : ""
        }

        // Always-visible caption strip (controls appear on hover).
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 34
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            width: 36; height: 36
            running: Session.player.mediaStatus === MediaPlayer.LoadingMedia
                     || Session.player.mediaStatus === MediaPlayer.BufferingMedia
            visible: running
        }

        HoverHandler { id: hover }
        TapHandler {
            onTapped: Session.page = "live"
        }
        DragHandler {
            id: drag
            target: root
            xAxis.minimum: root.bounds.x
            xAxis.maximum: root.bounds.x + root.bounds.width - root.width
            yAxis.minimum: root.bounds.y
            yAxis.maximum: root.bounds.y + root.bounds.height - root.height
            onActiveChanged: {
                if (active)
                    return
                // Snap to the nearest corner.
                const cx = root.x + root.width / 2 - root.bounds.x
                const cy = root.y + root.height / 2 - root.bounds.y
                root.corner = (cy < root.bounds.height / 2 ? 0 : 2) + (cx < root.bounds.width / 2 ? 0 : 1)
                root.x = Qt.binding(() => root.cornerX(root.corner))
                root.y = Qt.binding(() => root.cornerY(root.corner))
            }
        }

        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 10
            spacing: 6
            Rectangle {
                width: 7; height: 7; radius: 3.5
                color: Theme.live
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                width: root.width - 40
                text: Session.nowPlaying ? Session.nowPlaying.name : ""
                font: Theme.headline
                color: Theme.videoText
                elide: Text.ElideRight
            }
        }

        // ---- Hover overlay ------------------------------------------------
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            opacity: hover.hovered || drag.active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

            component MiniButton: AbstractButton {
                id: mini
                property string iconName
                property bool filledIcon: false
                width: 34; height: 34
                hoverEnabled: true
                background: Rectangle { radius: 17; color: mini.hovered ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.35) }
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        width: 15; height: 15
                        name: mini.iconName
                        filled: mini.filledIcon
                        strokeWidth: 2.4
                        color: Theme.videoText
                    }
                }
                scale: pressed ? 0.9 : 1
                Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
            }

            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 6
                MiniButton {
                    iconName: "fullscreen"
                    Accessible.name: qsTr("Back to Live TV")
                    onClicked: Session.page = "live"
                }
                MiniButton {
                    iconName: "close"
                    Accessible.name: qsTr("Close mini player")
                    onClicked: {
                        Session.miniPlayerDismissed = true
                        Session.stop()
                    }
                }
            }

            AbstractButton {
                anchors.centerIn: parent
                width: 46; height: 46
                Accessible.name: Session.isPlaying ? qsTr("Pause") : qsTr("Play")
                onClicked: Session.togglePlay()
                background: Rectangle { radius: 23; color: Theme.accent }
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        width: 16; height: 16
                        name: Session.isPlaying ? "pause" : "play"
                        filled: true
                        color: Theme.accentForeground
                    }
                }
                scale: pressed ? 0.9 : 1
                Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
            }

        }
    }
}

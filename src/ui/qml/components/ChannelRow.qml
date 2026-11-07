import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// One row of the channel list: number · logo · name · group.
ItemDelegate {
    id: control

    property int channelNumber
    property string channelName
    property string groupName
    property url logoUrl
    property bool current: false

    implicitHeight: 56
    hoverEnabled: true
    padding: 0
    Accessible.name: channelName

    background: Rectangle {
        radius: Theme.radiusMedium
        color: control.current ? Theme.raised : control.hovered ? Theme.hover : "transparent"
        border.width: control.current ? 1 : 0
        border.color: Theme.borderStrong
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    contentItem: Row {
        spacing: 10
        leftPadding: 8

        Label {
            width: 26
            text: control.channelNumber
            horizontalAlignment: Text.AlignRight
            font: Theme.caption
            color: Theme.textTertiary
            anchors.verticalCenter: parent.verticalCenter
        }
        ChannelLogo {
            width: 38; height: 38
            name: control.channelName
            source: control.logoUrl
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            width: control.width - 26 - 38 - 10 * 2 - 8 - 10
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Label {
                width: parent.width
                text: control.channelName
                font: Theme.headline
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            Label {
                width: parent.width
                visible: text.length > 0
                text: control.groupName
                font: Theme.caption
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }
    }

    // Accent marker for the playing channel.
    Rectangle {
        visible: control.current
        width: 3; height: 20; radius: 1.5
        color: Theme.accentText
        anchors.left: parent.left
        anchors.leftMargin: -1
        anchors.verticalCenter: parent.verticalCenter
    }
}

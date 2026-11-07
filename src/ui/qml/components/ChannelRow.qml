import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// One row of the channel list: number, logo, name and group.
ItemDelegate {
    id: control

    property int channelNumber
    property string channelName
    property string groupName
    property url logoUrl
    property bool current: false

    implicitHeight: 52
    hoverEnabled: true
    padding: 0
    Accessible.name: channelName

    background: Rectangle {
        radius: Theme.radiusSmall + 2
        color: control.current ? Theme.window
             : control.hovered ? Theme.cardHover : "transparent"
        border.width: control.current ? 1 : 0
        border.color: Theme.separator
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        Rectangle {
            visible: control.current
            width: 3; height: 18; radius: 1.5
            color: Theme.accent
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    contentItem: Row {
        spacing: 12
        leftPadding: 10

        Label {
            width: 30
            text: control.channelNumber
            horizontalAlignment: Text.AlignRight
            font: Theme.caption
            color: Theme.textTertiary
            anchors.verticalCenter: parent.verticalCenter
        }
        ChannelLogo {
            name: control.channelName
            source: control.logoUrl
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            width: control.width - 30 - 34 - 12 * 2 - 10 - 12
            spacing: 2
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
}

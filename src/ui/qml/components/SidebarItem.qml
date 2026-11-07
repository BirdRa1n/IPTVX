import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Navigation row in the sidebar: tinted icon, label, optional trailing text.
// The selection pill is drawn by the parent Sidebar so it can glide between
// items; this delegate only reports `selected`.
AbstractButton {
    id: control

    property string iconName
    property string trailing
    property bool selected: false
    property color dotColor: "transparent"

    implicitHeight: 34
    implicitWidth: 200
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.PageTab

    background: Rectangle {
        radius: Theme.radiusSmall
        color: !control.selected && control.hovered ? Theme.cardHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
    }

    contentItem: Row {
        leftPadding: 12
        rightPadding: 12
        spacing: 10

        Rectangle {
            visible: control.dotColor.a > 0
            width: 8; height: 8; radius: 4
            color: control.dotColor
            anchors.verticalCenter: parent.verticalCenter
        }
        Icon {
            visible: control.iconName.length > 0
            name: control.iconName
            width: 17; height: 17
            color: control.selected ? Theme.onAccent : Theme.accent
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: control.text
            font: control.selected ? Theme.headline : Theme.body
            color: control.selected ? Theme.onAccent : Theme.textPrimary
            elide: Text.ElideRight
            width: control.width - 12 * 2 - 27 - trailingLabel.implicitWidth - 10
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            id: trailingLabel
            text: control.trailing
            font: Theme.caption
            color: control.selected ? Qt.alpha(Theme.onAccent, 0.8) : Theme.textTertiary
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Press feedback: a subtle spring scale, like SwiftUI buttons.
    scale: pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutQuad } }
}

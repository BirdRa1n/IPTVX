import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Capsule button. `prominent` = filled accent (primary action),
// otherwise a quiet tinted capsule (secondary action).
AbstractButton {
    id: control

    property bool prominent: true
    property string iconName
    property color tint: Theme.accent
    property color foreground: prominent ? Theme.accentForeground : tint

    implicitHeight: 38
    implicitWidth: contentRow.implicitWidth + 36
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    background: Rectangle {
        radius: height / 2
        color: control.prominent
               ? (control.pressed ? Qt.darker(control.tint, 1.15) : control.tint)
               : (control.hovered ? Qt.alpha(control.tint, 0.20) : Qt.alpha(control.tint, 0.12))
        opacity: control.enabled ? 1 : 0.45
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.textPrimary
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8
            Icon {
                visible: control.iconName.length > 0
                name: control.iconName
                width: 15; height: 15
                filled: control.iconName === "play"
                color: control.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                text: control.text
                font: Theme.headline
                color: control.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    scale: pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutQuad } }
}

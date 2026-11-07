import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Workspace button.
// prominent: accent fill + dark label (primary action)
// otherwise: surface + hairline border (secondary action)
// `tint` turns a secondary button into a colored one (e.g. danger).
AbstractButton {
    id: control

    property bool prominent: true
    property string iconName
    property color tint: "transparent"
    readonly property bool tinted: tint.a > 0
    property color foreground: prominent ? Theme.accentForeground
                                         : tinted ? tint : Theme.textPrimary

    implicitHeight: Theme.controlHeight
    implicitWidth: contentRow.implicitWidth + 28
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    background: Rectangle {
        radius: Theme.radiusMedium
        color: control.prominent
               ? (control.pressed ? Qt.darker(Theme.accent, 1.08) : control.hovered ? Qt.lighter(Theme.accent, 1.05) : Theme.accent)
               : control.tinted ? Qt.alpha(control.tint, control.hovered ? 0.16 : 0.10)
                                : (control.hovered ? Theme.hover : Theme.surface)
        border.width: control.prominent || control.tinted ? 0 : 1
        border.color: Theme.border
        opacity: control.enabled ? 1 : 0.45
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: parent.radius + 3
            color: "transparent"
            border.width: 2
            border.color: Theme.accentText
            visible: control.visualFocus
        }
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
                filled: control.iconName === "play" || control.iconName === "pause"
                color: control.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                visible: control.text.length > 0
                text: control.text
                font: Theme.headline
                color: control.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    scale: pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutQuad } }
}

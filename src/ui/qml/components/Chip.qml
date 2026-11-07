import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Filter chip: accent fill when active, quiet chip color otherwise.
AbstractButton {
    id: control

    property bool active: false

    implicitHeight: 30
    implicitWidth: label.implicitWidth + 24
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.checked: active

    background: Rectangle {
        radius: Theme.radiusSmall
        color: control.active ? Theme.accent : control.hovered ? Theme.hover : Theme.chip
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accentText
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }
    contentItem: Label {
        id: label
        text: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 13
        font.weight: control.active ? Font.Bold : Font.Normal
        color: control.active ? Theme.accentForeground : Theme.chipText
    }
    scale: pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
}

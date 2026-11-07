import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// iOS-style switch: accent track, white knob that springs across.
Switch {
    id: control

    implicitWidth: 46
    implicitHeight: 28
    padding: 0
    spacing: 0

    indicator: Rectangle {
        width: 46
        height: 28
        radius: 14
        color: control.checked ? Theme.accent : Theme.field
        Behavior on color { ColorAnimation { duration: Theme.durationMedium } }

        Rectangle {
            width: 24
            height: 24
            radius: 12
            y: 2
            x: control.checked ? parent.width - width - 2 : 2
            color: "#FFFFFF"
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0.08)
            Behavior on x { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.25 } }
        }
    }

    contentItem: Item {}
}

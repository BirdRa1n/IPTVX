import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Switch: accent track when on; the knob springs across.
Switch {
    id: control

    implicitWidth: 44
    implicitHeight: 26
    padding: 0
    spacing: 0

    indicator: Rectangle {
        width: 44
        height: 26
        radius: 13
        color: control.checked ? Theme.accent : Theme.track
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accentText
        Behavior on color { ColorAnimation { duration: Theme.durationMedium } }

        Rectangle {
            width: 20
            height: 20
            radius: 10
            y: 3
            x: control.checked ? parent.width - width - 3 : 3
            color: control.checked ? Theme.accentForeground : (Theme.dark ? "#ECECEA" : "#FFFFFF")
            border.width: Theme.dark || control.checked ? 0 : 1
            border.color: Theme.borderStrong
            Behavior on x { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.25 } }
        }
    }

    contentItem: Item {}
}

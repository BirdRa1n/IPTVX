pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Segmented picker; the raised thumb slides between segments on a spring.
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitHeight: 34
    implicitWidth: segments.implicitWidth + 6
    radius: Theme.radiusMedium
    color: Theme.chip

    Rectangle {
        id: thumb
        y: 3
        height: parent.height - 6
        radius: Theme.radiusSmall
        color: Theme.dark ? "#3A3A3A" : Theme.surface
        border.width: Theme.dark ? 0 : 1
        border.color: Theme.border
        readonly property Item target: segments.children[root.currentIndex] ?? null
        x: target ? target.x + 3 : 3
        width: target ? target.width : 0
        Behavior on x { SpringAnimation { spring: 4.5; damping: 0.38; epsilon: 0.25 } }
        Behavior on width { SpringAnimation { spring: 4.5; damping: 0.38; epsilon: 0.25 } }
    }

    Row {
        id: segments
        x: 3
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.model
            delegate: AbstractButton {
                id: segment
                required property int index
                required property string modelData
                width: Math.max(64, label.implicitWidth + 28)
                height: root.height - 6
                Accessible.role: Accessible.RadioButton
                Accessible.name: segment.modelData
                checked: segment.index === root.currentIndex
                onClicked: { root.currentIndex = segment.index; root.activated(segment.index) }
                contentItem: Label {
                    id: label
                    text: segment.modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.callout.pixelSize
                    font.weight: segment.checked ? Font.Bold : Font.Normal
                    color: segment.checked ? Theme.textPrimary : Theme.textSecondary
                }
            }
        }
    }
}

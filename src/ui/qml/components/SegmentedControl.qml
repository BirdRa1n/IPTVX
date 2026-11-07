pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// SwiftUI-style segmented picker. The white "thumb" slides between
// segments with a soft spring.
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitHeight: 32
    implicitWidth: segments.implicitWidth + 4
    radius: Theme.radiusSmall + 1
    color: Theme.field

    Rectangle {
        id: thumb
        y: 2
        height: parent.height - 4
        radius: Theme.radiusSmall - 1
        color: Theme.dark ? "#5A5A60" : "#FFFFFF"
        readonly property Item target: segments.children[root.currentIndex] ?? null
        x: target ? target.x + 2 : 2
        width: target ? target.width : 0
        Behavior on x { SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.25 } }
        Behavior on width { SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.25 } }

        border.width: Theme.dark ? 0 : 0.5
        border.color: "#D8D8DE"
    }

    Row {
        id: segments
        x: 2
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.model
            delegate: AbstractButton {
                id: segment
                required property int index
                required property string modelData
                width: Math.max(64, label.implicitWidth + 28)
                height: root.height - 4
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
                    font.weight: segment.checked ? Font.DemiBold : Font.Normal
                    color: Theme.textPrimary
                }
            }
        }
    }
}

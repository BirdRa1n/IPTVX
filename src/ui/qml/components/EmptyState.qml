import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Centered illustration + message + optional action, with a gentle
// entrance (fade + rise) every time it becomes visible.
Item {
    id: root

    property string iconName: "tv"
    property string title
    property string message
    property string actionText
    signal actionTriggered()

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 16
        width: Math.min(parent.width - 48, 420)
        spacing: Theme.space3
        opacity: 0

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            radius: 22
            color: Theme.accentSoft
            Icon {
                anchors.centerIn: parent
                width: 34; height: 34
                name: root.iconName
                color: Theme.accent
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: Theme.space2
            text: root.title
            font: Theme.title2
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
        Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.message
            font: Theme.body
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            lineHeight: 1.2
        }
        PillButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.space3
            visible: root.actionText.length > 0
            text: root.actionText
            iconName: "plus"
            onClicked: root.actionTriggered()
        }

        ParallelAnimation {
            id: entrance
            NumberAnimation { target: column; property: "opacity"; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { target: column; property: "anchors.verticalCenterOffset"; to: 0; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
        }
    }

    onVisibleChanged: if (visible) { column.opacity = 0; column.anchors.verticalCenterOffset = 16; entrance.restart() }
    Component.onCompleted: entrance.start()
}

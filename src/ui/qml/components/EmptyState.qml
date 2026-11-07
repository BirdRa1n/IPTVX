import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Centered icon + message + optional action, with a gentle fade-and-rise
// entrance every time it becomes visible.
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
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 18
            color: Theme.accentSoft
            border.width: 1
            border.color: Qt.alpha(Theme.accentText, 0.35)
            Icon {
                anchors.centerIn: parent
                width: 28; height: 28
                name: root.iconName
                color: Theme.accentText
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: Theme.space2
            text: root.title
            font: Theme.title
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

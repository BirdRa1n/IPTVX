pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Compact icon-only navigation rail. The selection plate glides between
// destinations on a spring.
Rectangle {
    id: root

    signal addSourceRequested()

    implicitWidth: Theme.railWidth
    color: Theme.bg

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.divider
    }

    component RailButton: AbstractButton {
        id: button
        property string iconName
        property string page
        readonly property bool selected: page.length > 0 && Session.page === page

        width: 42
        height: 42
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        onClicked: if (page.length > 0) Session.page = page

        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: text

        background: Rectangle {
            radius: 12
            color: !button.selected && button.hovered ? Theme.hover : "transparent"
            border.width: button.visualFocus ? 2 : 0
            border.color: Theme.accentText
        }
        contentItem: Item {
            Icon {
                anchors.centerIn: parent
                width: 19; height: 19
                name: button.iconName
                color: button.selected ? Theme.accentText : Theme.textTertiary
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            }
        }
        scale: pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
    }

    Column {
        id: top
        width: parent.width
        topPadding: Qt.platform.os === "osx" ? 40 : 14
        spacing: 6

        Rectangle {
            width: 36; height: 36; radius: 11
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.accent
            Label {
                anchors.centerIn: parent
                text: "X"
                font.pixelSize: 16
                font.weight: Font.ExtraBold
                color: Theme.accentForeground
            }
        }
        Item { width: 1; height: 10 }

        Item {
            id: navItems
            width: parent.width
            height: nav.implicitHeight

            // Selection plate shared by all destinations.
            Rectangle {
                id: plate
                readonly property Item target: Session.page === "home" ? homeButton
                                             : Session.page === "live" ? liveButton
                                             : Session.page === "settings" ? settingsButton : null
                visible: target !== null && target.parent === nav
                width: 42; height: 42; radius: 12
                x: (parent.width - width) / 2
                y: target && target.parent === nav ? target.y : 0
                color: Theme.raised
                border.width: 1
                border.color: Theme.borderStrong
                Behavior on y { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.25 } }
            }

            Column {
                id: nav
                width: parent.width
                spacing: 6
                RailButton { id: homeButton; text: qsTr("Dashboard"); iconName: "grid"; page: "home" }
                RailButton { id: liveButton; text: qsTr("Live TV"); iconName: "tv"; page: "live" }
                RailButton { text: qsTr("Movies (soon)"); iconName: "film"; enabled: false; opacity: 0.4 }
                RailButton { text: qsTr("Favorites (soon)"); iconName: "star"; enabled: false; opacity: 0.4 }
                RailButton { id: settingsButton; text: qsTr("Settings"); iconName: "gear"; page: "settings" }
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        width: parent.width
        spacing: 6
        RailButton {
            text: Theme.dark ? qsTr("Switch to light appearance") : qsTr("Switch to dark appearance")
            iconName: "sun"
            onClicked: Session.appearance = Theme.dark ? "light" : "dark"
        }
        RailButton {
            text: qsTr("Add source")
            iconName: "plusCircle"
            onClicked: root.addSourceRequested()
        }
    }
}

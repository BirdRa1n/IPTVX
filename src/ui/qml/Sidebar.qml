pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Source-list style sidebar (macOS / SwiftUI NavigationSplitView look).
// The accent "selection pill" glides between rows with a spring.
Rectangle {
    id: root

    signal addSourceRequested()

    color: Theme.sidebar
    implicitWidth: Theme.sidebarWidth

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.sidebarBorder
    }

    Flickable {
        anchors.fill: parent
        anchors.bottomMargin: footer.height
        contentHeight: column.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: column
            width: parent.width
            implicitHeight: content.implicitHeight

            // Selection pill: follows the selected nav item.
            Rectangle {
                id: pill
                readonly property Item target: {
                    switch (Session.page) {
                    case "home": return homeItem
                    case "live": return liveItem
                    case "settings": return null
                    }
                    return null
                }
                visible: target !== null
                x: 12
                width: column.width - 24
                height: 34
                radius: Theme.radiusSmall
                color: Theme.accent
                y: target ? target.y : 0 // content Column sits at y = 0
                Behavior on y { SpringAnimation { spring: 5; damping: 0.38; epsilon: 0.25 } }
            }

            Column {
                id: content
                width: parent.width
                topPadding: Qt.platform.os === "osx" ? 40 : 20
                leftPadding: 12
                rightPadding: 12
                spacing: 2

                component SectionLabel: Label {
                    leftPadding: 12
                    topPadding: 14
                    bottomPadding: 4
                    font: Theme.sectionLabel
                    color: Theme.textTertiary
                }

                SectionLabel { text: qsTr("Watch"); topPadding: 4 }
                SidebarItem {
                    id: homeItem
                    drawsSelection: false
                    width: content.width - 24
                    text: qsTr("Home")
                    iconName: "home"
                    selected: Session.page === "home"
                    onClicked: Session.page = "home"
                }
                SidebarItem {
                    id: liveItem
                    drawsSelection: false
                    width: content.width - 24
                    text: qsTr("Live TV")
                    iconName: "tv"
                    trailing: Library.channels.totalCount > 0 ? Library.channels.totalCount.toLocaleString(Qt.locale(), "f", 0) : ""
                    selected: Session.page === "live"
                    onClicked: Session.page = "live"
                }
                SidebarItem {
                    width: content.width - 24
                    text: qsTr("Movies")
                    iconName: "film"
                    enabled: false
                    opacity: 0.45
                    trailing: qsTr("Soon")
                }
                SidebarItem {
                    width: content.width - 24
                    text: qsTr("Series")
                    iconName: "series"
                    enabled: false
                    opacity: 0.45
                    trailing: qsTr("Soon")
                }
                SidebarItem {
                    width: content.width - 24
                    text: qsTr("TV Guide")
                    iconName: "guide"
                    enabled: false
                    opacity: 0.45
                    trailing: qsTr("Soon")
                }

                SectionLabel { text: qsTr("Sources") }
                Repeater {
                    model: Library.sources
                    delegate: SidebarItem {
                        required property string sourceId
                        required property string name
                        required property string typeLabel
                        width: content.width - 24
                        text: name
                        trailing: typeLabel
                        dotColor: sourceId === Library.activeSourceId
                                  ? (Library.busy ? Theme.accent : Theme.success)
                                  : Theme.textTertiary
                        onClicked: Library.selectSource(sourceId)
                    }
                }
                Label {
                    visible: Library.sources.count === 0
                    leftPadding: 12
                    text: qsTr("No sources yet")
                    font: Theme.callout
                    color: Theme.textTertiary
                }
            }
        }
    }

    Column {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        padding: 12
        spacing: 2

        SidebarItem {
            width: footer.width - 24
            text: qsTr("Add Source")
            iconName: "plusCircle"
            onClicked: root.addSourceRequested()
        }
        SidebarItem {
            width: footer.width - 24
            text: qsTr("Settings")
            iconName: "gear"
            selected: Session.page === "settings"
            onClicked: Session.page = "settings"
        }
    }
}

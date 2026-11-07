pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Workspace top bar: source switcher, source status and the global search
// button that opens the command palette.
Rectangle {
    id: root

    signal paletteRequested()
    signal addSourceRequested()

    // macOS traffic lights sit over the rail (64 px), so the bar needs no
    // extra inset.
    implicitHeight: 62
    color: Theme.bg

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.divider
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        // ---- Source switcher ------------------------------------------
        AbstractButton {
            id: switcher
            Layout.preferredHeight: Theme.controlHeight
            implicitWidth: switcherRow.implicitWidth + 24
            hoverEnabled: true
            Accessible.name: qsTr("Switch source")
            onClicked: menu.opened ? menu.close() : menu.open()

            background: Rectangle {
                radius: Theme.radiusMedium
                color: switcher.hovered ? Theme.hover : Theme.surface
                border.width: 1
                border.color: Theme.border
            }
            contentItem: Item {
                implicitWidth: switcherRow.implicitWidth
                Row {
                    id: switcherRow
                    anchors.centerIn: parent
                    spacing: 10
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Library.busy ? Theme.warning : Library.activeSourceId.length > 0 ? Theme.accentText : Theme.textTertiary
                    }
                    Label {
                        text: Library.activeSourceName.length > 0 ? Library.activeSourceName : qsTr("No source")
                        font: Theme.headline
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Icon {
                        name: "chevronDown"
                        width: 14; height: 14
                        strokeWidth: 2.4
                        color: Theme.textSecondary
                        rotation: menu.opened ? 180 : 0
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on rotation { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Popup {
                id: menu
                y: switcher.height + 6
                width: 300
                padding: 6
                enter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium }
                        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.durationMedium; easing.type: Easing.OutCubic }
                    }
                }
                exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durationFast } }
                background: Rectangle {
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.borderStrong
                }
                contentItem: Column {
                    spacing: 2
                    Label {
                        leftPadding: 10
                        topPadding: 6
                        bottomPadding: 4
                        text: qsTr("SOURCES")
                        font: Theme.sectionLabel
                        color: Theme.textTertiary
                    }
                    Repeater {
                        model: Library.sources
                        delegate: ItemDelegate {
                            id: sourceItem
                            required property string sourceId
                            required property string name
                            required property string typeLabel
                            readonly property bool active: sourceId === Library.activeSourceId
                            width: 288
                            height: 40
                            onClicked: { Library.selectSource(sourceId); menu.close() }
                            background: Rectangle {
                                radius: Theme.radiusSmall
                                color: sourceItem.active ? Theme.chip : sourceItem.hovered ? Theme.hover : "transparent"
                            }
                            contentItem: RowLayout {
                                spacing: 10
                                Rectangle {
                                    Layout.leftMargin: 4
                                    Layout.preferredWidth: 8
                                    Layout.preferredHeight: 8
                                    radius: 4
                                    color: sourceItem.active ? Theme.accentText : Theme.textTertiary
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: sourceItem.name
                                    font: sourceItem.active ? Theme.headline : Theme.body
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.rightMargin: 4
                                    text: sourceItem.typeLabel
                                    font: Theme.caption
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }
                    Rectangle { width: 288; height: 1; color: Theme.divider }
                    ItemDelegate {
                        id: addItem
                        width: 288
                        height: 40
                        onClicked: { menu.close(); root.addSourceRequested() }
                        background: Rectangle { radius: Theme.radiusSmall; color: addItem.hovered ? Theme.hover : "transparent" }
                        contentItem: Row {
                            spacing: 10
                            leftPadding: 2
                            Icon { name: "plus"; width: 15; height: 15; color: Theme.accentText; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: qsTr("Add source…"); font: Theme.body; color: Theme.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: {
                if (Library.busy)
                    return qsTr("Loading…")
                if (Library.activeSourceId.length === 0)
                    return ""
                return qsTr("%L1 channels · %L2 groups").arg(Library.channels.totalCount).arg(Library.channels.groups.length)
            }
            font: Theme.callout
            color: Theme.textTertiary
            elide: Text.ElideRight
        }

        // ---- Search / command palette trigger ---------------------------
        AbstractButton {
            id: searchButton
            Layout.preferredHeight: Theme.controlHeight
            Layout.preferredWidth: 300
            hoverEnabled: true
            Accessible.name: qsTr("Search everything")
            onClicked: root.paletteRequested()
            background: Rectangle {
                radius: Theme.radiusMedium
                color: searchButton.hovered ? Theme.hover : Theme.surface
                border.width: 1
                border.color: Theme.border
            }
            contentItem: RowLayout {
                spacing: 8
                Icon { Layout.leftMargin: 12; Layout.preferredWidth: 15; Layout.preferredHeight: 15; name: "search"; color: Theme.textTertiary }
                Label { Layout.fillWidth: true; text: qsTr("Search everything"); font: Theme.callout; color: Theme.textTertiary }
                Label {
                    Layout.rightMargin: 8
                    text: Qt.platform.os === "osx" ? "⌘K" : "Ctrl K"
                    font: Theme.caption
                    color: Theme.chipText
                    leftPadding: 6
                    rightPadding: 6
                    topPadding: 1
                    bottomPadding: 1
                    background: Rectangle { radius: 5; color: Theme.chip }
                }
            }
        }
    }
}

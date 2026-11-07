pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Dashboard: greeting, continue watching, groups and source health.
Flickable {
    id: page

    signal addSourceRequested()
    signal paletteRequested()

    contentHeight: column.implicitHeight + Theme.space7 * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}

    component SectionHeader: RowLayout {
        id: header
        property string title
        property string detail
        Layout.fillWidth: true
        Label { text: header.title; font: Theme.title2; color: Theme.textPrimary }
        Item { Layout.fillWidth: true }
        Label { text: header.detail; font: Theme.callout; color: Theme.textTertiary }
    }

    ColumnLayout {
        id: column
        x: Theme.space7
        y: Theme.space6
        width: page.width - Theme.space7 * 2
        spacing: Theme.space6
        visible: Library.sources.count > 0

        ColumnLayout {
            spacing: 4
            Label { text: Theme.greeting(); font: Theme.largeTitle; color: Theme.textPrimary }
            Label {
                text: new Date().toLocaleDateString(Qt.locale(), "dddd, d MMMM")
                font: Theme.callout
                color: Theme.textTertiary
            }
        }

        // ---- Continue watching ------------------------------------------
        SectionHeader { title: qsTr("Continue watching") }

        AbstractButton {
            id: resume
            Layout.fillWidth: true
            Layout.preferredHeight: 132
            hoverEnabled: true
            enabled: Library.channels.totalCount > 0
            Accessible.name: qsTr("Resume %1").arg(resumeTitle.text)
            onClicked: {
                if (Session.playingRow < 0)
                    Session.play(0)
                Session.page = "live"
            }
            background: Rectangle {
                radius: Theme.radiusLarge
                color: resume.hovered ? Theme.hover : Theme.surface
                border.width: 1
                border.color: Theme.border
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            }
            contentItem: RowLayout {
                spacing: Theme.space4
                Rectangle {
                    Layout.leftMargin: Theme.space4
                    Layout.preferredWidth: 176
                    Layout.preferredHeight: 100
                    radius: Theme.radiusMedium
                    color: Theme.video
                    clip: true
                    ChannelLogo {
                        anchors.centerIn: parent
                        width: 48; height: 48
                        name: resumeTitle.text
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 4
                        color: Theme.track
                        Rectangle { width: parent.width * 0.47; height: 4; color: Theme.accent }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        text: Session.lastChannelUrl.length > 0 ? qsTr("LAST WATCHED") : qsTr("READY WHEN YOU ARE")
                        font: Theme.sectionLabel
                        color: Theme.accentText
                    }
                    Label {
                        id: resumeTitle
                        Layout.fillWidth: true
                        text: Session.lastChannelName.length > 0 ? Session.lastChannelName
                                                                 : (Library.activeSourceName || qsTr("Your library"))
                        font: Theme.title
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }
                    Label {
                        text: Library.busy ? qsTr("Loading channels…")
                                           : qsTr("Live · %1").arg(Library.activeSourceName)
                        font: Theme.callout
                        color: Theme.textSecondary
                    }
                }
                PillButton {
                    Layout.rightMargin: Theme.space5
                    text: qsTr("Watch")
                    iconName: "play"
                    enabled: resume.enabled
                    onClicked: resume.clicked()
                }
            }
            scale: pressed ? 0.99 : 1
            Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
        }

        // ---- Groups -----------------------------------------------------
        SectionHeader {
            visible: Library.channels.groups.length > 0
            title: qsTr("Groups")
            detail: qsTr("%L1 groups").arg(Library.channels.groups.length)
        }
        GridLayout {
            Layout.fillWidth: true
            visible: Library.channels.groups.length > 0
            columns: Math.max(2, Math.floor(column.width / 200))
            columnSpacing: Theme.space3
            rowSpacing: Theme.space3
            Repeater {
                model: Library.channels.groups.slice(0, 12)
                delegate: AbstractButton {
                    id: groupCell
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // equal columns
                    Layout.preferredHeight: 56
                    hoverEnabled: true
                    Accessible.name: modelData
                    onClicked: {
                        Library.channels.group = modelData
                        Session.page = "live"
                    }
                    background: Rectangle {
                        radius: Theme.radiusMedium
                        color: groupCell.hovered ? Theme.hover : Theme.cell
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        Rectangle {
                            Layout.leftMargin: 12
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.tint(groupCell.modelData)
                        }
                        Label {
                            Layout.fillWidth: true
                            text: groupCell.modelData
                            font: Theme.headline
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Icon { Layout.rightMargin: 12; Layout.preferredWidth: 14; Layout.preferredHeight: 14; name: "chevronRight"; color: Theme.textTertiary }
                    }
                }
            }
        }

        // ---- Sources ----------------------------------------------------
        SectionHeader { title: qsTr("Your sources"); detail: qsTr("%L1 configured").arg(Library.sources.count) }
        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor(column.width / 300))
            columnSpacing: Theme.space3
            rowSpacing: Theme.space3
            Repeater {
                model: Library.sources
                delegate: AbstractButton {
                    id: sourceCard
                    required property string sourceId
                    required property string name
                    required property string typeLabel
                    readonly property bool active: sourceId === Library.activeSourceId
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // equal columns
                    Layout.maximumWidth: 420
                    Layout.preferredHeight: 104
                    hoverEnabled: true
                    Accessible.name: name
                    onClicked: Library.selectSource(sourceId)
                    background: Rectangle {
                        radius: Theme.radiusLarge
                        color: sourceCard.hovered ? Theme.hover : Theme.surface
                        border.width: 1
                        border.color: sourceCard.active ? Theme.accentText : Theme.border
                    }
                    contentItem: ColumnLayout {
                        spacing: 8
                        RowLayout {
                            Layout.leftMargin: Theme.space4
                            Layout.rightMargin: Theme.space4
                            spacing: 8
                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 4
                                color: sourceCard.active ? (Library.busy ? Theme.warning : Theme.success) : Theme.textTertiary
                            }
                            Label { Layout.fillWidth: true; text: sourceCard.name; font: Theme.headline; color: Theme.textPrimary; elide: Text.ElideRight }
                            Label { text: sourceCard.typeLabel; font: Theme.caption; color: Theme.textSecondary }
                        }
                        Label {
                            Layout.leftMargin: Theme.space4
                            text: sourceCard.active && !Library.busy
                                  ? qsTr("%L1 live channels").arg(Library.channels.totalCount)
                                  : sourceCard.active ? qsTr("Loading…") : qsTr("Click to load")
                            font: Theme.callout
                            color: Theme.textPrimary
                        }
                        Label {
                            Layout.leftMargin: Theme.space4
                            text: sourceCard.active ? qsTr("Active source") : qsTr("Idle — not in memory")
                            font: Theme.caption
                            color: Theme.textTertiary
                        }
                    }
                }
            }
        }
    }

    EmptyState {
        width: page.width
        height: page.height
        visible: Library.sources.count === 0
        iconName: "tv"
        title: qsTr("Welcome to IPTVX")
        message: qsTr("IPTVX is a player: bring your own M3U playlist or Xtream Codes account to get started.")
        actionText: qsTr("Add Your First Source")
        onActionTriggered: page.addSourceRequested()
    }
}

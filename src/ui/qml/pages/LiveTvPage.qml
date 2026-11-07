pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Live TV: channel list (search + group chips) beside the player.
Item {
    id: page

    signal fullScreenRequested(bool on)
    property bool fullScreen: false

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Channel list pane -------------------------------------------
        Rectangle {
            id: listPane
            Layout.fillHeight: true
            Layout.preferredWidth: page.fullScreen ? 0 : 340
            visible: Layout.preferredWidth > 0
            color: Theme.sidebar
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.sidebarBorder }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Qt.platform.os === "osx" ? 36 : Theme.space5
                spacing: Theme.space3

                ColumnLayout {
                    Layout.leftMargin: Theme.space4
                    Layout.rightMargin: Theme.space4
                    spacing: Theme.space3

                    RowLayout {
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Live TV")
                            font: Theme.title
                            color: Theme.textPrimary
                        }
                        Label {
                            text: Library.channels.count === Library.channels.totalCount
                                  ? qsTr("%L1 channels").arg(Library.channels.count)
                                  : qsTr("%L1 of %L2").arg(Library.channels.count).arg(Library.channels.totalCount)
                            font: Theme.caption
                            color: Theme.textTertiary
                        }
                    }

                    SearchField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Search channels")
                        text: Library.channels.searchText
                        onDebounced: value => Library.channels.searchText = value
                    }
                }

                // Group chips
                ListView {
                    id: chips
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    orientation: ListView.Horizontal
                    spacing: 6
                    leftMargin: Theme.space4
                    rightMargin: Theme.space4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: [""].concat(Library.channels.groups)
                    delegate: AbstractButton {
                        id: chip
                        required property string modelData
                        readonly property bool active: Library.channels.group === modelData
                        height: 28
                        width: chipLabel.implicitWidth + 26
                        Accessible.name: chipLabel.text
                        onClicked: Library.channels.group = modelData
                        background: Rectangle {
                            radius: 14
                            color: chip.active ? Theme.accent : Theme.field
                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        }
                        contentItem: Label {
                            id: chipLabel
                            text: chip.modelData === "" ? qsTr("All") : chip.modelData
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 12
                            font.weight: chip.active ? Font.DemiBold : Font.Normal
                            color: chip.active ? Theme.accentForeground : Theme.textPrimary
                        }
                    }
                }

                // Channel list. ListView only instantiates visible delegates
                // (plus a small cache buffer) and reuses them while scrolling,
                // so 100k channels cost the same as 20 in QML objects.
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    reuseItems: true
                    cacheBuffer: 240
                    spacing: 2
                    leftMargin: 8
                    rightMargin: 8
                    bottomMargin: 12
                    model: Library.channels
                    currentIndex: Session.playingRow
                    highlightFollowsCurrentItem: false
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: ChannelRow {
                        required property int index
                        required property string name
                        required property string group
                        required property string logo
                        required property int number
                        width: ListView.view.width - 16
                        channelNumber: number
                        channelName: name
                        groupName: group
                        logoUrl: logo
                        current: index === Session.playingRow
                        onClicked: Session.play(index)
                    }

                    // Gentle insert animation when the filter changes.
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationFast } }

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: Library.busy
                        visible: running
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: !Library.busy && list.count === 0 && Library.channels.totalCount > 0
                        text: qsTr("No channels match your search")
                        font: Theme.callout
                        color: Theme.textSecondary
                    }
                }
            }
        }

        // ---- Player ---------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: page.fullScreen ? 0 : Theme.space5
            spacing: Theme.space5

            VideoPlayer {
                id: player
                Layout.fillWidth: true
                Layout.fillHeight: page.fullScreen
                Layout.preferredHeight: page.fullScreen ? -1 : width * 9 / 16
                Layout.maximumHeight: page.fullScreen ? Number.POSITIVE_INFINITY : page.height * 0.68
                radius: page.fullScreen ? 0 : Theme.radiusLarge
                source: Session.nowPlaying ? Session.nowPlaying.url : ""
                title: Session.nowPlaying ? Session.nowPlaying.name : ""
                onPreviousRequested: Session.step(-1)
                onNextRequested: Session.step(1)
                onFullScreenRequested: page.fullScreenRequested(!page.fullScreen)
                Behavior on radius { NumberAnimation { duration: Theme.durationMedium } }
            }

            // Now playing card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                visible: !page.fullScreen && Session.nowPlaying !== null
                radius: Theme.radiusMedium + 2
                color: Theme.card

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space4
                    spacing: Theme.space4
                    ChannelLogo {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        radius: Theme.radiusMedium
                        name: Session.nowPlaying ? Session.nowPlaying.name : ""
                        source: Session.nowPlaying ? Session.nowPlaying.logo : ""
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: qsTr("NOW PLAYING")
                            font: Theme.sectionLabel
                            color: Theme.accent
                        }
                        Label {
                            Layout.fillWidth: true
                            text: Session.nowPlaying ? Session.nowPlaying.name : ""
                            font: Theme.title2
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: Session.nowPlaying ? Session.nowPlaying.group : ""
                            font: Theme.callout
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true; visible: !page.fullScreen }
        }
    }

    EmptyState {
        anchors.fill: parent
        visible: Library.sources.count === 0
        iconName: "tv"
        title: qsTr("No channels yet")
        message: qsTr("Add an M3U playlist or an Xtream Codes account to start watching live TV.")
    }

    Keys.onEscapePressed: if (page.fullScreen) page.fullScreenRequested(false)
}

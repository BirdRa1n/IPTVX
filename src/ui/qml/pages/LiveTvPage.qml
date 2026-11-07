pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Live TV workspace: channel pane (filter + chips + list) beside the
// player and an "up next" ribbon.
Item {
    id: page

    signal fullScreenRequested(bool on)
    property bool fullScreen: false

    // Next channels after the playing one, for the ribbon (max 5 maps).
    readonly property var upNext: {
        const count = Library.channels.count
        const from = Session.playingRow < 0 ? 0 : Session.playingRow + 1
        const items = []
        for (let i = from; i < Math.min(from + 5, count); ++i) {
            const item = Library.channels.get(i)
            item.row = i
            items.push(item)
        }
        return items
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Channel pane ------------------------------------------------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: page.fullScreen ? 0 : Theme.listPaneWidth
            visible: Layout.preferredWidth > 0
            color: Theme.bg
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.divider }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Theme.space3
                spacing: Theme.space3

                SearchField {
                    Layout.fillWidth: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    placeholderText: qsTr("Filter channels")
                    text: Library.channels.searchText
                    onDebounced: value => Library.channels.searchText = value
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    orientation: ListView.Horizontal
                    spacing: 6
                    leftMargin: 14
                    rightMargin: 14
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: [""].concat(Library.channels.groups)
                    delegate: Chip {
                        required property string modelData
                        text: modelData === "" ? qsTr("All") : modelData
                        active: Library.channels.group === modelData
                        onClicked: Library.channels.group = modelData
                    }
                }

                Label {
                    Layout.leftMargin: 18
                    text: Library.channels.count === Library.channels.totalCount
                          ? qsTr("%L1 channels").arg(Library.channels.count)
                          : qsTr("%L1 of %L2 channels").arg(Library.channels.count).arg(Library.channels.totalCount)
                    font: Theme.caption
                    color: Theme.textTertiary
                }

                // ListView only instantiates visible delegates (plus a small
                // cache) and reuses them: 100k channels cost the same as 20.
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

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: Library.busy
                        visible: running
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: !Library.busy && list.count === 0 && Library.channels.totalCount > 0
                        text: qsTr("No channels match")
                        font: Theme.callout
                        color: Theme.textSecondary
                    }
                }
            }
        }

        // ---- Player + ribbon ----------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: page.fullScreen ? 0 : Theme.space4
            spacing: Theme.space4

            VideoPlayer {
                Layout.fillWidth: true
                Layout.fillHeight: page.fullScreen
                Layout.preferredHeight: page.fullScreen ? -1 : width * 9 / 16
                Layout.maximumHeight: page.fullScreen ? Number.POSITIVE_INFINITY : page.height * 0.66
                radius: page.fullScreen ? 0 : Theme.radiusLarge
                source: Session.nowPlaying ? Session.nowPlaying.url : ""
                title: Session.nowPlaying ? Session.nowPlaying.name : ""
                subtitle: Session.nowPlaying ? Session.nowPlaying.group : ""
                onPreviousRequested: Session.step(-1)
                onNextRequested: Session.step(1)
                onFullScreenRequested: page.fullScreenRequested(!page.fullScreen)
            }

            // Up-next ribbon (becomes the EPG ribbon once XMLTV lands).
            ColumnLayout {
                Layout.fillWidth: true
                visible: !page.fullScreen && page.upNext.length > 0
                spacing: Theme.space2

                RowLayout {
                    spacing: Theme.space3
                    Label {
                        text: Library.channels.group.length > 0 ? qsTr("Up next in %1").arg(Library.channels.group) : qsTr("Up next")
                        font: Theme.headline
                        color: Theme.textPrimary
                    }
                    Label { text: qsTr("Programme guide arrives with XMLTV support"); font: Theme.caption; color: Theme.textTertiary }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: page.upNext
                        delegate: AbstractButton {
                            id: cell
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1 // equal cells
                            Layout.preferredHeight: 58
                            hoverEnabled: true
                            Accessible.name: modelData.name
                            onClicked: Session.play(modelData.row)
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                color: cell.hovered ? Theme.hover : Theme.cell
                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                            }
                            contentItem: ColumnLayout {
                                spacing: 2
                                Label {
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.fillWidth: true
                                    text: cell.modelData.number
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Theme.textPrimary
                                }
                                Label {
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.fillWidth: true
                                    text: cell.modelData.name
                                    font: Theme.caption
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
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

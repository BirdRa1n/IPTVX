pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// ⌘K / Ctrl+K command palette: searches channels of the active source
// (Library.search — a second index view over the same catalog) and app
// commands. Arrow keys move, Enter runs, Escape closes.
Popup {
    id: commandPalette

    signal addSourceRequested()

    modal: true
    focus: true
    x: Math.round((parent.width - width) / 2)
    y: 96
    width: Math.min(620, parent.width - 48)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property int current: 0

    // Static commands; filtered by the query.
    readonly property var allCommands: [
        { label: qsTr("Go to Dashboard"), hint: qsTr("Navigation"), run: () => Session.page = "home" },
        { label: qsTr("Go to Live TV"), hint: qsTr("Navigation"), run: () => Session.page = "live" },
        { label: qsTr("Open Settings"), hint: qsTr("Navigation"), run: () => Session.page = "settings" },
        { label: qsTr("Add source…"), hint: qsTr("Sources"), run: () => commandPalette.addSourceRequested() },
        { label: qsTr("Refresh current source"), hint: qsTr("Sources"), run: () => Library.refresh() },
        { label: qsTr("Switch to light appearance"), hint: qsTr("Appearance"), run: () => Session.appearance = "light" },
        { label: qsTr("Switch to dark appearance"), hint: qsTr("Appearance"), run: () => Session.appearance = "dark" },
        { label: qsTr("Follow system appearance"), hint: qsTr("Appearance"), run: () => Session.appearance = "system" }
    ]
    readonly property var commands: {
        const q = query.text.trim().toLowerCase()
        return q.length === 0 ? allCommands.slice(0, 4)
                              : allCommands.filter(c => c.label.toLowerCase().indexOf(q) >= 0)
    }
    readonly property int channelCount: Math.min(Library.search.count, 6)
    readonly property int total: channelCount + commands.length

    function activate(index) {
        if (index < channelCount) {
            const item = Library.search.get(index)
            Session.playNumber(item.number)
            Session.page = "live"
        } else if (index - channelCount < commands.length) {
            commands[index - channelCount].run()
        }
        close()
    }

    onAboutToShow: { query.text = ""; current = 0; query.forceActiveFocus() }
    onClosed: Library.search.searchText = ""

    Overlay.modal: Rectangle { color: Theme.scrim }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershoot }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durationFast } }

    background: Rectangle {
        radius: Theme.radiusXL
        color: Theme.surface
        border.width: 1
        border.color: Theme.borderStrong
    }

    component SectionTitle: Label {
        leftPadding: 10
        topPadding: 8
        bottomPadding: 4
        font: Theme.sectionLabel
        color: Theme.textTertiary
    }

    component ResultRow: ItemDelegate {
        id: row
        property int resultIndex
        property string title
        property string detail
        property string trailing
        property Item leading: null
        readonly property bool active: commandPalette.current === resultIndex
        width: parent ? parent.width : 0
        height: 46
        hoverEnabled: true
        onHoveredChanged: if (hovered) commandPalette.current = resultIndex
        onClicked: commandPalette.activate(resultIndex)
        background: Rectangle {
            radius: Theme.radiusMedium
            color: row.active ? Theme.chip : "transparent"
        }
        contentItem: RowLayout {
            spacing: 10
            Item {
                Layout.leftMargin: 4
                Layout.preferredWidth: row.leading ? 30 : 0
                Layout.preferredHeight: 30
                data: row.leading ? [row.leading] : []
            }
            Label { text: row.title; font: Theme.headline; color: Theme.textPrimary }
            Label { Layout.fillWidth: true; text: row.detail; font: Theme.caption; color: Theme.textSecondary; elide: Text.ElideRight }
            Label {
                Layout.rightMargin: 6
                text: row.active ? row.trailing : ""
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Theme.accentText
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 6
            spacing: 10
            Icon { Layout.leftMargin: 12; Layout.preferredWidth: 18; Layout.preferredHeight: 18; name: "search"; color: Theme.textTertiary }
            TextField {
                id: query
                objectName: "paletteQuery"
                Layout.fillWidth: true
                implicitHeight: 48
                placeholderText: qsTr("Search channels or run a command")
                placeholderTextColor: Theme.textTertiary
                color: Theme.textPrimary
                font.pixelSize: 18
                selectionColor: Theme.accentSoft
                background: null
                onTextChanged: { commandPalette.current = 0; debounce.restart() }
                Keys.onDownPressed: commandPalette.current = Math.min(commandPalette.current + 1, commandPalette.total - 1)
                Keys.onUpPressed: commandPalette.current = Math.max(commandPalette.current - 1, 0)
                Keys.onReturnPressed: if (commandPalette.total > 0) commandPalette.activate(commandPalette.current)
                Keys.onEnterPressed: if (commandPalette.total > 0) commandPalette.activate(commandPalette.current)
                Timer {
                    id: debounce
                    interval: 120
                    onTriggered: Library.search.searchText = query.text
                }
            }
            Label {
                Layout.rightMargin: 12
                text: "esc"
                font: Theme.caption
                color: Theme.textSecondary
                leftPadding: 7
                rightPadding: 7
                topPadding: 2
                bottomPadding: 2
                background: Rectangle { radius: 6; color: "transparent"; border.width: 1; border.color: Theme.border }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

        Column {
            Layout.fillWidth: true
            Layout.margins: 8
            spacing: 2

            SectionTitle { visible: commandPalette.channelCount > 0; text: qsTr("CHANNELS") }
            Repeater {
                model: Library.search
                delegate: ResultRow {
                    id: channelResult
                    required property int index
                    required property string name
                    required property string group
                    required property string logo
                    visible: index < 6
                    height: visible ? 46 : 0
                    resultIndex: index
                    title: name
                    detail: group
                    trailing: qsTr("↵ Watch")
                    leading: ChannelLogo { width: 30; height: 30; radius: 8; name: channelResult.name; source: channelResult.logo }
                }
            }

            SectionTitle { visible: commandPalette.commands.length > 0; text: qsTr("COMMANDS") }
            Repeater {
                model: commandPalette.commands
                delegate: ResultRow {
                    required property int index
                    required property var modelData
                    resultIndex: commandPalette.channelCount + index
                    title: modelData.label
                    detail: modelData.hint
                    trailing: qsTr("↵ Run")
                }
            }

            Label {
                visible: commandPalette.total === 0
                width: parent.width
                padding: 18
                text: qsTr("No results")
                horizontalAlignment: Text.AlignHCenter
                font: Theme.callout
                color: Theme.textSecondary
            }
        }
    }
}

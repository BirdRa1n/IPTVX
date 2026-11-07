pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Settings in grouped, inset "Form" sections (SwiftUI Form style).
Flickable {
    id: page

    signal updateRequested()

    contentHeight: column.implicitHeight + Theme.space7 * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}

    function formatBytes(bytes) {
        if (bytes < 1024)
            return bytes + " B"
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " KiB"
        return (bytes / 1048576).toFixed(2) + " MiB"
    }

    component Section: ColumnLayout {
        id: section
        property string title
        default property alias content: box.data
        Layout.fillWidth: true
        spacing: Theme.space2
        Label {
            text: section.title.toUpperCase()
            leftPadding: Theme.space4
            font: Theme.sectionLabel
            color: Theme.textTertiary
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: box.implicitHeight
            radius: Theme.radiusLarge
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
            ColumnLayout {
                id: box
                width: parent.width
                spacing: 0
            }
        }
    }

    component FormRow: RowLayout {
        id: formRow
        property string label
        default property alias trailing: holder.data
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        Layout.leftMargin: Theme.space4
        Layout.rightMargin: Theme.space4
        Label {
            Layout.fillWidth: true
            text: formRow.label
            font: Theme.body
            color: Theme.textPrimary
        }
        RowLayout { id: holder; spacing: Theme.space2 }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.space4
        implicitHeight: 1
        color: Theme.divider
    }

    ColumnLayout {
        id: column
        // Readable form width, centred in the page.
        width: Math.min(page.width - Theme.space7 * 2, 760)
        x: Math.round((page.width - width) / 2)
        y: Theme.space6
        spacing: Theme.space6

        Label {
            text: qsTr("Settings")
            font: Theme.largeTitle
            color: Theme.textPrimary
        }

        Section {
            title: qsTr("Appearance")
            FormRow {
                label: qsTr("Theme")
                SegmentedControl {
                    model: [qsTr("System"), qsTr("Light"), qsTr("Dark")]
                    currentIndex: ["system", "light", "dark"].indexOf(Session.appearance)
                    onActivated: index => Session.appearance = ["system", "light", "dark"][index]
                }
            }
            Divider {}
            FormRow {
                label: qsTr("Accent color")
                Repeater {
                    model: Theme.accentPresets.map(p => p.fill)
                    delegate: AbstractButton {
                        id: swatch
                        required property string modelData
                        width: 24; height: 24
                        Accessible.name: modelData
                        onClicked: Session.accent = modelData
                        background: Rectangle {
                            radius: 12
                            color: swatch.modelData
                            border.width: Session.accent === swatch.modelData ? 3 : 0
                            border.color: Theme.surface
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -3
                                radius: 15
                                color: "transparent"
                                border.width: 2
                                border.color: swatch.modelData
                                visible: Session.accent === swatch.modelData
                            }
                        }
                    }
                }
            }
            Divider {}
            FormRow {
                label: qsTr("Reduce motion")
                ToggleSwitch {
                    checked: Session.reduceMotion
                    onToggled: Session.reduceMotion = checked
                }
            }
        }

        Section {
            title: qsTr("Sources")
            Repeater {
                model: Library.sources
                delegate: FormRow {
                    id: sourceRow
                    required property string sourceId
                    required property string name
                    required property string typeLabel
                    label: name + "  ·  " + typeLabel
                    PillButton {
                        visible: sourceRow.sourceId === Library.activeSourceId
                        text: qsTr("Refresh")
                        iconName: "refresh"
                        prominent: false
                        implicitHeight: 30
                        enabled: !Library.busy
                        onClicked: Library.refresh()
                    }
                    PillButton {
                        text: qsTr("Remove")
                        iconName: "trash"
                        prominent: false
                        tint: Theme.danger
                        implicitHeight: 30
                        onClicked: Library.removeSource(sourceRow.sourceId)
                    }
                }
            }
            Label {
                visible: Library.sources.count === 0
                Layout.margins: Theme.space4
                text: qsTr("No sources configured.")
                font: Theme.body
                color: Theme.textSecondary
            }
        }

        Section {
            title: qsTr("About")
            FormRow {
                label: qsTr("Version")
                Label { text: Qt.application.version + " · " + Updates.platformLabel; font: Theme.body; color: Theme.textSecondary }
            }
            Divider {}
            FormRow {
                label: {
                    switch (Updates.state) {
                    case Updates.Checking: return qsTr("Checking for updates…")
                    case Updates.UpToDate: return qsTr("IPTVX is up to date")
                    case Updates.Available: return qsTr("Version %1 is available").arg(Updates.latestVersion)
                    case Updates.Downloading: return qsTr("Downloading update… %1%").arg(Math.round(Updates.progress * 100))
                    case Updates.ReadyToInstall: return qsTr("Update ready to install")
                    case Updates.Failed: return qsTr("Update check failed")
                    }
                    return qsTr("Updates")
                }
                PillButton {
                    text: Updates.state === Updates.Available || Updates.state === Updates.ReadyToInstall
                          ? qsTr("View update") : qsTr("Check now")
                    prominent: Updates.state === Updates.Available || Updates.state === Updates.ReadyToInstall
                    implicitHeight: 30
                    enabled: Updates.state !== Updates.Checking && Updates.state !== Updates.Downloading
                    onClicked: {
                        if (Updates.state === Updates.Available || Updates.state === Updates.ReadyToInstall) {
                            Updates.dismissed = false
                            page.updateRequested()
                        } else {
                            Updates.check()
                        }
                    }
                }
            }
            Divider {}
            FormRow {
                label: qsTr("Check for updates on launch")
                ToggleSwitch {
                    checked: Updates.autoCheck
                    onToggled: Updates.autoCheck = checked
                }
            }
            Divider {}
            FormRow {
                label: qsTr("Channel catalog in memory")
                Label {
                    // Re-evaluated whenever the catalog changes.
                    text: Library.channels.totalCount >= 0 ? page.formatBytes(Library.catalogMemory()) : ""
                    font: Theme.body
                    color: Theme.textSecondary
                }
            }
        }
    }
}

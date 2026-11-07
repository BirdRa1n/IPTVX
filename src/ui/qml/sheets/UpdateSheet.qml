pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// "A new version is available": release notes, download progress and the
// install-and-restart action.
Popup {
    id: sheet

    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(560, (parent ? parent.width : 560) - 48)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property bool busy: Updates.state === Updates.Downloading

    function formatSize(bytes) {
        if (bytes <= 0)
            return ""
        return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : Math.round(bytes / 1024) + " KB"
    }

    Overlay.modal: Rectangle { color: Theme.scrim }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershoot }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.durationFast } }

    background: Rectangle {
        radius: Theme.radiusXL
        color: Theme.surface
        border.width: 1
        border.color: Theme.borderStrong
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.space5
            spacing: Theme.space4

            Image {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                source: "qrc:/icons/iptvx-256.png"
                sourceSize: Qt.size(112, 112)
                smooth: true
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: qsTr("IPTVX %1 is available").arg(Updates.latestVersion)
                    font: Theme.title2
                    color: Theme.textPrimary
                }
                Label {
                    text: qsTr("You have %1 · %2").arg(Updates.currentVersion).arg(Updates.platformLabel)
                    font: Theme.callout
                    color: Theme.textSecondary
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

        // Release notes (Markdown from the GitHub release).
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(notes.implicitHeight, 260)
            clip: true
            Label {
                id: notes
                width: sheet.width - Theme.space5 * 2
                x: Theme.space5
                topPadding: Theme.space4
                bottomPadding: Theme.space4
                text: Updates.releaseNotes.length > 0 ? Updates.releaseNotes : qsTr("No release notes.")
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                font: Theme.body
                color: Theme.textPrimary
                linkColor: Theme.accentText
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

        // Progress / status
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space5
            Layout.rightMargin: Theme.space5
            Layout.topMargin: Theme.space4
            spacing: Theme.space2
            visible: sheet.busy || Updates.state === Updates.ReadyToInstall
                     || Updates.state === Updates.Failed || !Updates.canInstall

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                visible: sheet.busy || Updates.state === Updates.ReadyToInstall
                radius: 3
                color: Theme.track
                Rectangle {
                    width: parent.width * Updates.progress
                    height: parent.height
                    radius: 3
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: Theme.durationFast } }
                }
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font: Theme.callout
                color: Updates.state === Updates.Failed ? Theme.danger : Theme.textSecondary
                text: {
                    if (Updates.state === Updates.Failed)
                        return Updates.errorString
                    if (!Updates.canInstall)
                        return qsTr("There is no automatic installer for %1 in this release. Download it from the release page.").arg(Updates.platformLabel)
                    if (Updates.state === Updates.ReadyToInstall)
                        return qsTr("Downloaded and verified. IPTVX will restart to finish the update.")
                    return qsTr("Downloading… %1%").arg(Math.round(Updates.progress * 100))
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.space5
            spacing: Theme.space2

            PillButton {
                text: qsTr("Release page")
                prominent: false
                onClicked: Updates.openReleasePage()
            }
            Item { Layout.fillWidth: true }
            PillButton {
                text: sheet.busy ? qsTr("Cancel") : qsTr("Later")
                prominent: false
                onClicked: {
                    if (sheet.busy)
                        Updates.cancelDownload()
                    Updates.dismissed = true
                    sheet.close()
                }
            }
            PillButton {
                visible: Updates.canInstall
                enabled: !sheet.busy
                iconName: Updates.state === Updates.ReadyToInstall ? "refresh" : "download"
                text: Updates.state === Updates.ReadyToInstall ? qsTr("Restart and update")
                    : qsTr("Download %1").arg(sheet.formatSize(Updates.downloadSize))
                onClicked: Updates.state === Updates.ReadyToInstall ? Updates.installAndRestart()
                                                                    : Updates.download()
            }
        }
    }
}

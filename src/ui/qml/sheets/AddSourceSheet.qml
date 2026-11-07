pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import IPTVX.UI

// Modal sheet to add an M3U URL, a local M3U file or an Xtream account.
// Enters with a spring scale + fade over a dimmed backdrop.
Popup {
    id: sheet

    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(560, (parent ? parent.width : 560) - 48)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property int kind: 0 // 0 = URL, 1 = File, 2 = Xtream
    property url pickedFile

    function reset() {
        kind = 0
        nameField.text = ""
        urlField.text = ""
        uaField.text = ""
        serverField.text = ""
        userField.text = ""
        passField.text = ""
        pickedFile = ""
        Library.clearError()
    }

    function submit() {
        let ok = false
        if (kind === 0)
            ok = Library.addM3uUrl(nameField.text, urlField.text, uaField.text)
        else if (kind === 1)
            ok = Library.addM3uFile(nameField.text, pickedFile)
        else
            ok = Library.addXtream(nameField.text, serverField.text, userField.text, passField.text)
        if (ok) {
            Session.page = "live"
            close()
        }
    }

    onAboutToShow: reset()

    Overlay.modal: Rectangle {
        color: Theme.scrim
        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium } }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutBack; easing.overshoot: Theme.springOvershoot }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.durationFast }
            NumberAnimation { property: "scale"; to: 0.96; duration: Theme.durationFast }
        }
    }

    background: Rectangle {
        radius: Theme.radiusXL
        color: Theme.surface
        border.width: Theme.dark ? 1 : 0
        border.color: Theme.divider
    }

    component FieldLabel: Label {
        font: Theme.caption
        color: Theme.textSecondary
    }

    component Field: TextField {
        Layout.fillWidth: true
        implicitHeight: 40
        leftPadding: 12
        font: Theme.body
        color: Theme.textPrimary
        placeholderTextColor: Theme.textTertiary
        selectionColor: Theme.accentSoft
        background: Rectangle {
            radius: Theme.radiusMedium
            color: Theme.bg
            border.width: parent.activeFocus ? 2 : 1
            border.color: parent.activeFocus ? Theme.accentText : Theme.border
        }
        onAccepted: sheet.submit()
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.space5
            Layout.bottomMargin: Theme.space2
            Label {
                Layout.fillWidth: true
                text: qsTr("Add a Source")
                font: Theme.title2
                color: Theme.textPrimary
            }
            AbstractButton {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Accessible.name: qsTr("Close")
                onClicked: sheet.close()
                background: Rectangle { radius: 15; color: Theme.chip }
                contentItem: Item { Icon { anchors.centerIn: parent; width: 13; height: 13; name: "close"; strokeWidth: 2.6; color: Theme.textSecondary } }
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space5
            Layout.rightMargin: Theme.space5
            text: qsTr("IPTVX is a player — bring your own playlist or provider account.")
            font: Theme.callout
            color: Theme.textSecondary
            wrapMode: Text.Wrap
        }

        SegmentedControl {
            Layout.fillWidth: true
            Layout.margins: Theme.space5
            model: [qsTr("M3U URL"), qsTr("M3U File"), qsTr("Xtream Codes")]
            currentIndex: sheet.kind
            onActivated: index => sheet.kind = index
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space5
            Layout.rightMargin: Theme.space5
            spacing: Theme.space2

            FieldLabel { text: qsTr("Name") }
            Field { id: nameField; placeholderText: qsTr("Optional") }

            // M3U URL
            ColumnLayout {
                visible: sheet.kind === 0
                Layout.fillWidth: true
                spacing: Theme.space2
                FieldLabel { text: qsTr("Playlist URL"); Layout.topMargin: Theme.space2 }
                Field { id: urlField; placeholderText: "https://example.com/playlist.m3u" }
                FieldLabel { text: qsTr("User-Agent"); Layout.topMargin: Theme.space2 }
                Field { id: uaField; placeholderText: qsTr("Optional") }
            }

            // M3U File
            ColumnLayout {
                visible: sheet.kind === 1
                Layout.fillWidth: true
                Layout.topMargin: Theme.space2
                AbstractButton {
                    id: dropZone
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    hoverEnabled: true
                    onClicked: fileDialog.open()
                    background: Rectangle {
                        radius: Theme.radiusMedium
                        color: dropZone.hovered ? Theme.accentSoft : "transparent"
                        border.width: 1.5
                        border.color: dropZone.hovered ? Theme.accentText : Theme.border
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }
                    contentItem: ColumnLayout {
                        spacing: Theme.space2
                        Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 26; Layout.preferredHeight: 26; name: "file"; color: Theme.accentText }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: dropZone.width - 32
                            text: sheet.pickedFile.toString().length > 0
                                  ? decodeURIComponent(sheet.pickedFile.toString().split("/").pop())
                                  : qsTr("Choose an .m3u / .m3u8 file")
                            font: Theme.callout
                            color: Theme.textSecondary
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // Xtream
            ColumnLayout {
                visible: sheet.kind === 2
                Layout.fillWidth: true
                spacing: Theme.space2
                FieldLabel { text: qsTr("Server URL"); Layout.topMargin: Theme.space2 }
                Field { id: serverField; placeholderText: "http://provider.example.com:8080" }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space2
                    spacing: Theme.space3
                    ColumnLayout {
                        Layout.fillWidth: true
                        FieldLabel { text: qsTr("Username") }
                        Field { id: userField }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        FieldLabel { text: qsTr("Password") }
                        Field { id: passField; echoMode: TextInput.Password }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space2
                visible: Library.errorString.length > 0
                text: Library.errorString
                font: Theme.callout
                color: Theme.danger
                wrapMode: Text.Wrap
            }
        }

        // Footer
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.space5
            Layout.topMargin: Theme.space6
            spacing: Theme.space2
            Item { Layout.fillWidth: true }
            PillButton {
                text: qsTr("Cancel")
                prominent: false
                onClicked: sheet.close()
            }
            PillButton {
                text: qsTr("Add Source")
                enabled: sheet.kind === 0 ? urlField.text.length > 0
                       : sheet.kind === 1 ? sheet.pickedFile.toString().length > 0
                       : serverField.text.length > 0 && userField.text.length > 0
                onClicked: sheet.submit()
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Choose a playlist")
        nameFilters: [qsTr("Playlists (*.m3u *.m3u8)"), qsTr("All files (*)")]
        onAccepted: sheet.pickedFile = selectedFile
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

ApplicationWindow {
    id: window

    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 620
    visible: true
    title: Library.activeSourceName.length > 0 ? "IPTVX — " + Library.activeSourceName : "IPTVX"
    color: Theme.window

    // Unified title bar on macOS: content extends under the traffic lights.
    flags: Qt.platform.os === "osx" ? (Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint) : Qt.Window

    property bool immersive: false

    // Draw edge to edge: pages handle the title-bar inset themselves.
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: window.immersive ? 0 : Theme.sidebarWidth
            visible: Layout.preferredWidth > 0
            clip: true
            onAddSourceRequested: addSheet.open()
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }
        }

        // Pages are created on demand and destroyed when left (StackView
        // replace), so an unused page never holds memory.
        StackView {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: homePage

            replaceEnter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.985; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
                }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast; easing.type: Easing.InCubic }
            }
        }
    }

    Component {
        id: homePage
        HomePage { onAddSourceRequested: addSheet.open() }
    }
    Component {
        id: livePage
        LiveTvPage {
            fullScreen: window.immersive
            onFullScreenRequested: on => {
                window.immersive = on
                if (on) window.showFullScreen()
                else window.showNormal()
            }
        }
    }
    Component {
        id: settingsPage
        SettingsPage {}
    }

    Connections {
        target: Session
        function onPageChanged() {
            if (Session.page !== "live" && window.immersive) {
                window.immersive = false
                window.showNormal()
            }
            const page = Session.page === "live" ? livePage
                       : Session.page === "settings" ? settingsPage : homePage
            stack.replace(null, page)
        }
    }

    AddSourceSheet { id: addSheet }

    // Global shortcuts
    Shortcut { sequence: "Ctrl+1"; onActivated: Session.page = "home" }
    Shortcut { sequence: "Ctrl+2"; onActivated: Session.page = "live" }
    Shortcut { sequences: [StandardKey.Preferences]; onActivated: Session.page = "settings" }
    Shortcut { sequences: [StandardKey.New]; onActivated: addSheet.open() }
    Shortcut { sequence: "Ctrl+F"; onActivated: Session.page = "live" }

    // Error toast for failures that happen outside the add-source sheet.
    Rectangle {
        id: toast
        readonly property bool shown: Library.errorString.length > 0 && !addSheet.opened
        anchors.horizontalCenter: parent.horizontalCenter
        y: shown ? parent.height - height - 24 : parent.height + 10
        Behavior on y { NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutBack } }
        width: Math.min(toastText.implicitWidth + 48, parent.width - 48)
        height: 44
        radius: 22
        color: Theme.dark ? "#3A2224" : "#FFF0F0"
        border.width: 1
        border.color: Qt.alpha(Theme.danger, 0.4)
        Label {
            id: toastText
            anchors.centerIn: parent
            width: parent.width - 32
            text: Library.errorString
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font: Theme.callout
            color: Theme.danger
        }
        TapHandler { onTapped: Library.clearError() }
    }
}

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
    color: Theme.bg
    Behavior on color { ColorAnimation { duration: Theme.durationMedium } }

    // Unified title bar on macOS: content extends under the traffic lights.
    flags: Qt.platform.os === "osx" ? (Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint) : Qt.Window

    property bool immersive: false

    // Union rect of the native window controls (macOS traffic lights), set by
    // the app after styling the native title bar. Empty on other platforms.
    property rect titleBarControls: Qt.rect(0, 0, 0, 0)
    // In full screen macOS hides the traffic lights (and the app hides the
    // native toolbar), so no title-bar strip has to be reserved.
    readonly property bool nativeControls: titleBarControls.width > 0 && visibility !== Window.FullScreen
    // The top bar is as tall as the native title bar, so its controls share
    // the traffic lights' vertical centre.
    readonly property int topBarHeight: nativeControls
        ? Math.max(44, Math.round(2 * (titleBarControls.y + titleBarControls.height / 2)))
        : 62
    readonly property real controlsRight: nativeControls ? titleBarControls.x + titleBarControls.width : 0

    // Draw edge to edge: the rail and top bar handle the title-bar inset.
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rail {
            headerHeight: window.nativeControls ? window.topBarHeight : 0
            Layout.fillHeight: true
            Layout.preferredWidth: window.immersive ? 0 : Theme.railWidth
            visible: Layout.preferredWidth > 0
            clip: true
            onAddSourceRequested: addSheet.open()
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TopBar {
                implicitHeight: window.topBarHeight
                // Keep clear of the traffic lights when they spill past the rail.
                leadingInset: Math.max(18, window.controlsRight + 18 - Theme.railWidth)
                Layout.fillWidth: true
                Layout.preferredHeight: window.immersive ? 0 : implicitHeight
                visible: Layout.preferredHeight > 0
                clip: true
                onPaletteRequested: commandPalette.open()
                onAddSourceRequested: addSheet.open()
            }

            // Pages are created on demand and destroyed when left (StackView
            // replace), so an unused page never holds memory.
            StackView {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                initialItem: dashboardPage

                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "y"; from: 10; to: 0; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
                    }
                }
                replaceExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast; easing.type: Easing.InCubic }
                }
            }
        }
    }

    Component {
        id: dashboardPage
        DashboardPage {
            onAddSourceRequested: addSheet.open()
            onPaletteRequested: commandPalette.open()
        }
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
                       : Session.page === "settings" ? settingsPage : dashboardPage
            stack.replace(null, page)
        }
    }

    // In-app picture-in-picture: keeps the current channel on screen while
    // browsing other pages. Lives in the content area (below the top bar,
    // right of the rail).
    MiniPlayer {
        wanted: Session.page !== "live" && !window.immersive
        bounds: Qt.rect(Theme.railWidth, window.topBarHeight,
                        window.width - Theme.railWidth, window.height - window.topBarHeight)
    }

    AddSourceSheet { id: addSheet }
    CommandPalette {
        id: commandPalette
        objectName: "commandPalette"
        onAddSourceRequested: addSheet.open()
    }

    // Global shortcuts
    Shortcut { sequence: "Ctrl+K"; onActivated: commandPalette.opened ? commandPalette.close() : commandPalette.open() }
    Shortcut { sequence: "Ctrl+1"; onActivated: Session.page = "home" }
    Shortcut { sequence: "Ctrl+2"; onActivated: Session.page = "live" }
    Shortcut { sequences: [StandardKey.Preferences]; onActivated: Session.page = "settings" }
    Shortcut { sequences: [StandardKey.New]; onActivated: addSheet.open() }
    Shortcut { sequences: [StandardKey.Find]; onActivated: commandPalette.open() }

    // Error toast for failures that happen outside the add-source sheet.
    Rectangle {
        id: toast
        readonly property bool shown: Library.errorString.length > 0 && !addSheet.opened
        anchors.horizontalCenter: parent.horizontalCenter
        y: shown ? parent.height - height - 24 : parent.height + 10
        Behavior on y { NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutBack } }
        width: Math.min(toastText.implicitWidth + 48, parent.width - 48)
        height: 44
        radius: Theme.radiusLarge
        color: Theme.surface
        border.width: 1
        border.color: Qt.alpha(Theme.danger, 0.5)
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

import QtQuick
import QtQuick.Controls.Basic

// Creates its Popup (sourceComponent) only when opened and destroys it once
// it has closed, so sheets, dialogs and the command palette cost no memory
// while they are not on screen.
Loader {
    id: lazy

    readonly property Popup popup: item as Popup
    readonly property bool opened: popup !== null && popup.opened

    function open() {
        active = true
        if (popup)
            popup.open()
    }
    function close() {
        if (popup)
            popup.close()
    }

    active: false
    // The popup sizes itself from its parent (this loader): span the window.
    // A Loader handles no input, so it never blocks the UI underneath.
    anchors.fill: parent

    Connections {
        target: lazy.item
        ignoreUnknownSignals: true
        // After the exit transition has finished.
        function onClosed() { Qt.callLater(() => lazy.active = false) }
    }
}

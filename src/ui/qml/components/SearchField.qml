import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Search input with a leading magnifier and a clear button.
// `debounced` fires 180 ms after typing stops so large lists are not
// re-filtered on every keystroke.
TextField {
    id: control

    signal debounced(string value)

    implicitHeight: Theme.controlHeight
    leftPadding: 34
    rightPadding: clearButton.visible ? 32 : 12
    font: Theme.callout
    color: Theme.textPrimary
    placeholderTextColor: Theme.textTertiary
    selectionColor: Theme.accentSoft
    selectedTextColor: Theme.textPrimary
    placeholderText: qsTr("Search")
    Accessible.name: placeholderText

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.surface
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Theme.accentText : Theme.border
    }

    Icon {
        name: "search"
        width: 15; height: 15
        color: Theme.textTertiary
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    AbstractButton {
        id: clearButton
        visible: control.text.length > 0
        width: 22; height: 22
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        Accessible.name: qsTr("Clear search")
        onClicked: control.clear()
        contentItem: Icon { name: "close"; color: Theme.textTertiary; strokeWidth: 2.4 }
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: control.debounced(control.text)
    }
    onTextChanged: debounce.restart()
}

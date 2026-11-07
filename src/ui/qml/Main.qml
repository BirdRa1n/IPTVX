import QtQuick
import QtQuick.Controls.Basic

ApplicationWindow {
    id: window

    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: qsTr("IPTVX")

    Label {
        anchors.centerIn: parent
        text: qsTr("IPTVX")
        font.pixelSize: 34
        font.weight: Font.ExtraBold
    }
}

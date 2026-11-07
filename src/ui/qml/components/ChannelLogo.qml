import QtQuick
import QtQuick.Controls.Basic
import IPTVX.UI

// Channel artwork with a colored monogram fallback.
//
// Memory: the logo is decoded at the displayed size (`sourceSize`), loaded
// asynchronously, and only while the delegate exists (ListView recycles
// delegates), so thousands of channels never hold thousands of bitmaps.
Rectangle {
    id: root

    property string name
    property url source

    implicitWidth: 34
    implicitHeight: 34
    radius: Theme.radiusSmall + 1
    color: image.status === Image.Ready ? (Theme.dark ? "#FFFFFF14" : "#00000008") : Theme.tint(name)
    clip: true

    Label {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: Theme.monogram(root.name)
        color: "#FFFFFF"
        font.pixelSize: Math.round(root.height * 0.36)
        font.weight: Font.Bold
    }

    Image {
        id: image
        anchors.fill: parent
        anchors.margins: 3
        source: root.source
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
        sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
        smooth: true
        mipmap: false
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium } }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import IPTVX.UI

// Home: large title, featured "continue watching" card, library stats and
// a grid of channel groups.
Flickable {
    id: page

    signal addSourceRequested()

    contentHeight: column.implicitHeight + Theme.space7 * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}

    ColumnLayout {
        id: column
        x: Theme.space7
        y: Qt.platform.os === "osx" ? 36 : Theme.space6
        width: page.width - Theme.space7 * 2
        spacing: Theme.space6
        visible: Library.sources.count > 0

        // ---- Header --------------------------------------------------------
        ColumnLayout {
            spacing: 2
            Label {
                text: new Date().toLocaleDateString(Qt.locale(), "dddd, d MMMM").toUpperCase()
                font: Theme.sectionLabel
                color: Theme.textTertiary
            }
            Label {
                text: qsTr("Home")
                font: Theme.largeTitle
                color: Theme.textPrimary
            }
        }

        // ---- Featured card -------------------------------------------------
        Rectangle {
            id: hero
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            radius: Theme.radiusLarge + 2
            color: "#1E2A3A"
            clip: true

            // Decorative orbs drift slowly (disabled with reduced motion).
            Rectangle {
                id: orbA
                width: 420; height: 420; radius: 210
                color: "#2E4A6B"
                x: hero.width - 380; y: -60
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: !Theme.reduceMotion && page.visible
                    NumberAnimation { to: hero.width - 340; duration: 9000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: hero.width - 380; duration: 9000; easing.type: Easing.InOutSine }
                }
            }
            Rectangle {
                width: 220; height: 220; radius: 110
                color: Qt.alpha(Theme.accent, 0.55)
                x: hero.width - 340; y: 40
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Theme.space6
                width: Math.min(parent.width - Theme.space6 * 2, 520)
                spacing: Theme.space2

                Label {
                    text: Session.lastChannelUrl.length > 0 ? qsTr("CONTINUE WATCHING") : qsTr("READY WHEN YOU ARE")
                    font: Theme.sectionLabel
                    color: "#D5DEE9"
                    padding: 4
                    leftPadding: 8
                    rightPadding: 8
                    background: Rectangle { radius: 6; color: Qt.rgba(1, 1, 1, 0.18) }
                }
                Label {
                    Layout.fillWidth: true
                    text: Session.lastChannelName.length > 0
                          ? Session.lastChannelName
                          : (Library.activeSourceName || qsTr("Your library"))
                    font: Theme.title
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                }
                Label {
                    text: Library.busy ? qsTr("Loading channels…")
                                       : qsTr("%L1 channels · %L2 groups").arg(Library.channels.totalCount).arg(Library.channels.groups.length)
                    font: Theme.body
                    color: "#D5DEE9"
                }
                RowLayout {
                    Layout.topMargin: Theme.space2
                    spacing: Theme.space2
                    PillButton {
                        text: qsTr("Watch Live")
                        iconName: "play"
                        tint: "#FFFFFF"
                        prominent: true
                        foreground: "#111111"
                        enabled: Library.channels.totalCount > 0
                        onClicked: {
                            if (Session.playingRow < 0)
                                Session.play(0)
                            Session.page = "live"
                        }
                    }
                    PillButton {
                        text: qsTr("Browse Channels")
                        prominent: false
                        tint: "#FFFFFF"
                        onClicked: Session.page = "live"
                    }
                }
            }
        }

        // ---- Groups ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            visible: Library.channels.groups.length > 0
            Label {
                Layout.fillWidth: true
                text: qsTr("Browse by Group")
                font: Theme.title2
                color: Theme.textPrimary
            }
            Label {
                text: qsTr("%L1 groups").arg(Library.channels.groups.length)
                font: Theme.callout
                color: Theme.textSecondary
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(2, Math.floor(column.width / 220))
            columnSpacing: Theme.space3
            rowSpacing: Theme.space3

            Repeater {
                // Show the first groups only; the full list lives in Live TV.
                model: Library.channels.groups.slice(0, 24)
                delegate: AbstractButton {
                    id: card
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    hoverEnabled: true
                    Accessible.name: modelData
                    onClicked: {
                        Library.channels.group = modelData
                        Session.page = "live"
                    }
                    background: Rectangle {
                        radius: Theme.radiusMedium + 2
                        color: card.hovered ? Theme.cardHover : Theme.card
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }
                    contentItem: RowLayout {
                        spacing: Theme.space3
                        ChannelLogo {
                            Layout.leftMargin: Theme.space4
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: Theme.radiusMedium
                            name: card.modelData
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.rightMargin: Theme.space4
                            text: card.modelData
                            font: Theme.headline
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }
                    }
                    scale: pressed ? 0.97 : (hovered ? 1.015 : 1)
                    Behavior on scale { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutBack } }
                }
            }
        }
    }

    EmptyState {
        width: page.width
        height: page.height
        visible: Library.sources.count === 0
        iconName: "tv"
        title: qsTr("Welcome to IPTVX")
        message: qsTr("IPTVX is a player: bring your own M3U playlist or Xtream Codes account to get started.")
        actionText: qsTr("Add Your First Source")
        onActionTriggered: page.addSourceRequested()
    }
}

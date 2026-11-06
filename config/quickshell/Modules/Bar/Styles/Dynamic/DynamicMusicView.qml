import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Styles.Side

Item {
    id: root

    signal activated()

    readonly property var player: MprisService.activePlayer
    readonly property string title: player ? (player.trackTitle || "Unknown title") : "Nothing playing"
    readonly property string artist: player ? (player.trackArtist || "") : ""

    implicitWidth: 210
    implicitHeight: 32

    Rectangle {
        id: art

        x: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: SideState.cardHi

        Item {
            id: artMask

            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                radius: width / 2
            }
        }

        Image {
            anchors.fill: parent
            source: root.player ? (root.player.trackArtUrl || "") : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(64, 64)
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }
        }
    }

    SideText {
        anchors.left: art.right
        anchors.leftMargin: 9
        anchors.right: parent.right
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        text: root.title + (root.artist !== "" ? "  ·  " + root.artist : "")
        customSize: 12
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

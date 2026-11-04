import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Components
import qs.Core.Services

SidePill {
    id: root

    property bool vertical: false
    readonly property var player: MprisService.activePlayer
    readonly property bool active: player !== null && player !== undefined
    readonly property string label: player ? ((player.trackTitle || "") + (player.trackArtist ? "  ·  " + player.trackArtist : "")) : ""

    signal hoverChanged(bool on)

    implicitWidth: vertical ? SideState.railSize : Math.min(240, 26 + 10 + metrics.width + 22)
    implicitHeight: vertical ? SideState.railSize : SideState.railSize
    color: area.containsMouse || AppState.isWidgetOpen("music") ? Qt.tint(SideState.surface, SideState.card) : SideState.surface

    Behavior on color { ColorAnimation { duration: Constants.animFast } }

    TextMetrics {
        id: metrics

        text: root.label
        font.family: Constants.fontFamily
        font.pixelSize: Math.round(12 * SettingsService.fontScale)
    }

    Rectangle {
        id: art

        anchors.verticalCenter: parent.verticalCenter
        x: root.vertical ? (parent.width - width) / 2 : 5
        width: 26
        height: 26
        radius: 13
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

        RotationAnimator on rotation {
            running: MprisService.isPlaying && root.visible
            from: 0
            to: 360
            duration: 14000
            loops: Animation.Infinite
        }
    }

    SideText {
        visible: !root.vertical
        anchors.left: art.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        customSize: 12
        elide: Text.ElideRight
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleWidget("music")
        onContainsMouseChanged: root.hoverChanged(containsMouse)
    }
}

import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    readonly property var player: MprisService.activePlayer
    readonly property real length: player && player.length > 0 && player.length < 100000 ? player.length : 0
    readonly property real position: player ? player.position : 0

    function stamp(s) {
        if (s < 0)
            return "0:00";
        const m = Math.floor(s / 60), sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    implicitWidth: 400
    implicitHeight: 132

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        CaelCover {
            Layout.preferredWidth: 108
            Layout.preferredHeight: 108
            Layout.alignment: Qt.AlignVCenter
            source: root.player ? (root.player.trackArtUrl || "") : ""
            playing: MprisService.isPlaying
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            SideText {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
                color: SideState.primary
                customSize: 15
                font.bold: true
                elide: Text.ElideRight
            }

            SideText {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist || root.player.trackAlbum || "Unknown artist") : "Start something in any player"
                color: SideState.muted
                customSize: 12
                elide: Text.ElideRight
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.length > 0

                SideText {
                    text: root.stamp(root.position)
                    customSize: 10
                    color: SideState.muted
                }

                CaelMediaSlider {
                    Layout.fillWidth: true
                    value: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0
                    playing: MprisService.isPlaying
                    seekable: root.player !== null && root.player.canSeek && root.player.positionSupported && root.length > 0
                    onSeek: (f) => root.player.position = root.length * f
                }

                SideText {
                    text: root.stamp(root.length)
                    customSize: 10
                    color: SideState.muted
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                CaelIconButton {
                    Layout.preferredHeight: 38
                    Layout.preferredWidth: 46
                    Layout.minimumWidth: 46
                    icon: "player-previous"
                    iconSize: 18
                    disabled: !root.player || !root.player.canGoPrevious
                    onClicked: root.player.previous()
                }

                CaelIconButton {
                    Layout.preferredHeight: 38
                    Layout.preferredWidth: 64
                    Layout.minimumWidth: 64
                    tonal: false
                    checked: MprisService.isPlaying
                    icon: MprisService.isPlaying ? "player-pause" : "player-play"
                    iconSize: 20
                    disabled: !root.player || !root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
                }

                CaelIconButton {
                    Layout.preferredHeight: 38
                    Layout.preferredWidth: 46
                    Layout.minimumWidth: 46
                    icon: "player-next"
                    iconSize: 18
                    disabled: !root.player || !root.player.canGoNext
                    onClicked: root.player.next()
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }

    Timer {
        running: MprisService.isPlaying && root.visible
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: if (root.player) root.player.positionChanged()
    }
}

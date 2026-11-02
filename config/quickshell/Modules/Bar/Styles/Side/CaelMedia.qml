import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Media tab: large player with the source name and a second line for the album.
Item {
    id: root

    implicitHeight: Math.round(410 * Math.max(1, SettingsService.fontScale))

    CaelCard {
        anchors.fill: parent
        corner: 36

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24

            CaelMediaCard {
                Layout.preferredWidth: 380
                Layout.fillHeight: true
                large: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                SideText {
                    text: MprisService.activePlayerName !== "" ? MprisService.activePlayerName : "No player"
                    color: SideState.primary
                    font.bold: true
                    customSize: 13
                }

                SideText {
                    Layout.fillWidth: true
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackAlbum || "") : ""
                    color: SideState.muted
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Item {
                    Layout.fillHeight: true
                }

                SideText {
                    Layout.fillWidth: true
                    text: MprisService.activePlayer ? MprisService.formatTime(MprisService.activePlayer.position) + " / " + MprisService.formatTime(MprisService.activePlayer.length) : ""
                    color: SideState.muted
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

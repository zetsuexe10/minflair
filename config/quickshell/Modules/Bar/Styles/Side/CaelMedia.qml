import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Media tab: large player with the source name and a second line for the album.
Item {
    id: root

    implicitWidth: 730
    implicitHeight: 410

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

                ThemedText {
                    text: MprisService.activePlayerName !== "" ? MprisService.activePlayerName : "No player"
                    color: Theme.accent
                    font.bold: true
                    customSize: 13
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackAlbum || "") : ""
                    color: Theme.muted
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Item {
                    Layout.fillHeight: true
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: MprisService.activePlayer ? MprisService.formatTime(MprisService.activePlayer.position) + " / " + MprisService.formatTime(MprisService.activePlayer.length) : ""
                    color: Theme.muted
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

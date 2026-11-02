import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Cover, title, progress and controls. Used by the dashboard (compact) and the Media tab (large).
Item {
    id: root

    property bool large: false
    readonly property var player: MprisService.activePlayer
    readonly property real progress: (player && player.length > 0) ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    implicitWidth: large ? 420 : 200
    implicitHeight: large ? 340 : 410

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.large ? 24 : 16
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.large ? 190 : 168
            Layout.preferredHeight: width
            radius: root.large ? 32 : 28
            color: SideState.cardHi
            clip: true

            Image {
                id: art

                anchors.fill: parent
                source: root.player ? (root.player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(400, 400)
                visible: status === Image.Ready
                asynchronous: true
            }

            SvgIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                icon: "music"
                iconSize: 44
                iconColor: SideState.muted
                flat: true
            }
        }

        SideText {
            Layout.fillWidth: true
            Layout.topMargin: 4
            horizontalAlignment: Text.AlignHCenter
            text: root.player ? (root.player.trackTitle || "Not playing") : "No player"
            customSize: root.large ? 16 : 13
            font.bold: true
            elide: Text.ElideRight
        }

        SideText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.player ? (root.player.trackArtist || "") : "Open a music player"
            color: SideState.muted
            elide: Text.ElideRight
        }

        Item {
            Layout.fillHeight: true
        }

        // progress
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(SideState.fg.r, SideState.fg.g, SideState.fg.b, 0.12)

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: 3
                color: SideState.primary

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.Linear } }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                enabled: root.player !== null && root.player.canSeek
                onClicked: (m) => root.player.position = root.player.length * Math.max(0, Math.min(1, m.x / width))
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Repeater {
                model: [
                    { "icon": "player-previous", "act": 0 },
                    { "icon": "player-play", "act": 1 },
                    { "icon": "player-next", "act": 2 }
                ]

                Rectangle {
                    id: btn

                    required property var modelData
                    readonly property bool main: modelData.act === 1

                    Layout.preferredWidth: main ? 52 : 40
                    Layout.preferredHeight: main ? 52 : 40
                    radius: main ? (MprisService.isPlaying ? 16 : 26) : 20
                    color: main ? SideState.primary : (bh.hovered ? SideState.cardHi : SideState.card)

                    Behavior on radius { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: Constants.animFast } }

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: btn.main ? (MprisService.isPlaying ? "player-pause" : "player-play") : btn.modelData.icon
                        iconSize: btn.main ? 22 : 18
                        iconColor: btn.main ? SideState.surface : SideState.fg
                        flat: true
                    }

                    HoverHandler {
                        id: bh

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: root.player !== null
                        onTapped: {
                            if (btn.modelData.act === 0)
                                root.player.previous();
                            else if (btn.modelData.act === 1)
                                root.player.togglePlaying();
                            else
                                root.player.next();
                        }
                    }
                }
            }
        }
    }
}

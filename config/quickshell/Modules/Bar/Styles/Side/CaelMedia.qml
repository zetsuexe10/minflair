import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    readonly property var player: MprisService.activePlayer
    readonly property real length: player && player.length > 0 && player.length < 100000 ? player.length : 0
    readonly property bool unknownLength: player && player.length >= 100000
    readonly property real position: player ? player.position : 0
    property bool picking: false

    function lengthStr(s) {
        if (s < 0)
            return "-1:-1";
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = Math.floor(s % 60);
        const ss = (sec < 10 ? "0" : "") + sec;
        return h > 0 ? h + ":" + (m < 10 ? "0" : "") + m + ":" + ss : m + ":" + ss;
    }

    implicitHeight: Math.round(410 * Math.max(1, SettingsService.fontScale))

    Component.onCompleted: {
        CavaService.users++;
        LyricsService.users++;
    }
    Component.onDestruction: {
        CavaService.users--;
        LyricsService.users--;
    }

    Timer {
        running: MprisService.isPlaying
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: if (root.player) root.player.positionChanged()
    }

    CaelCard {
        anchors.fill: parent
        corner: 36

        RowLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 22

            CaelCover {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Math.min(parent.height, parent.width * 0.44)
                Layout.preferredHeight: Layout.preferredWidth
                source: root.player ? (root.player.trackArtUrl || "") : ""
                playing: MprisService.isPlaying
                visualiser: true
                visible: root.player !== null
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player === null
                spacing: 10

                Item {
                    Layout.fillHeight: true
                }

                SvgIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "music"
                    iconSize: 56
                    iconColor: SideState.muted
                    flat: true
                }

                SideText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Nothing playing"
                    customSize: 20
                    font.bold: true
                }

                SideText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Start a song in any player and it shows up here"
                    color: SideState.muted
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                id: content

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player !== null
                spacing: 2

                SideText {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                    customSize: 24
                    font.bold: true
                    elide: Text.ElideRight
                }

                SideText {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackArtist || "Unknown artist") : ""
                    color: SideState.muted
                    customSize: 15
                    elide: Text.ElideRight
                }

                SideText {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackAlbum || "Unknown album") : ""
                    color: SideState.secondary
                    customSize: 14
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    spacing: 10

                    SideText {
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignHCenter
                        text: root.lengthStr(root.position)
                        color: SideState.muted
                        customSize: 12
                    }

                    CaelMediaSlider {
                        Layout.fillWidth: true
                        value: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0
                        playing: MprisService.isPlaying
                        seekable: root.player !== null && root.player.canSeek && root.player.positionSupported && root.length > 0
                        onSeek: (f) => root.player.position = root.length * f
                    }

                    SideText {
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignHCenter
                        text: root.unknownLength ? "--:--" : root.lengthStr(root.length)
                        color: SideState.muted
                        customSize: 12
                    }
                }

                CaelMediaControls {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 10

                    RowLayout {
                        id: lyHead

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        SvgIcon {
                            icon: "music"
                            iconSize: 14
                            iconColor: SideState.muted
                            flat: true
                        }

                        SideText {
                            text: "Lyrics"
                            color: SideState.muted
                            customSize: 12
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        SideText {
                            visible: LyricsService.state === "ok" && !LyricsService.synced
                            text: "not synced"
                            color: SideState.muted
                            customSize: 11
                        }
                    }

                    ListView {
                        id: lyrics

                        readonly property int current: {
                            if (!LyricsService.synced)
                                return -1;
                            const t = root.position + 0.15;
                            let idx = -1;
                            for (let i = 0; i < LyricsService.lines.length; i++) {
                                if (LyricsService.lines[i].t <= t)
                                    idx = i;
                                else
                                    break;
                            }
                            return idx;
                        }

                        anchors.top: lyHead.bottom
                        anchors.topMargin: 6
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: selector.top
                        anchors.bottomMargin: 8
                        clip: true
                        model: LyricsService.lines
                        visible: LyricsService.state === "ok"
                        boundsBehavior: Flickable.StopAtBounds
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        preferredHighlightBegin: height / 2 - 14
                        preferredHighlightEnd: height / 2 + 14
                        highlightMoveDuration: 380
                        currentIndex: Math.max(0, current)
                        interactive: !LyricsService.synced

                        delegate: SideText {
                            required property var modelData
                            required property int index
                            readonly property bool now: index === lyrics.current

                            width: lyrics.width
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.text !== "" ? modelData.text : "♪"
                            wrapMode: Text.WordWrap
                            customSize: now ? 15 : 13
                            font.bold: now
                            color: now ? SideState.primary : SideState.muted
                            opacity: now ? 1 : (LyricsService.synced ? 0.55 : 0.9)

                            Behavior on opacity { NumberAnimation { duration: 250 } }
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    SideText {
                        anchors.centerIn: lyrics
                        visible: LyricsService.state !== "ok"
                        text: LyricsService.state === "loading" ? "Looking for lyrics..." : "No lyrics found"
                        color: SideState.muted
                    }

                    Rectangle {
                        id: selector

                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width, selLabel.implicitWidth + 56)
                        height: 34
                        radius: 17
                        color: selHover.hovered ? SideState.cardHi : SideState.selected
                        opacity: MprisService.selectable.length > 0 ? 1 : 0.4

                        Behavior on color { ColorAnimation { duration: Constants.animFast } }

                        SideText {
                            id: selLabel

                            anchors.verticalCenter: parent.verticalCenter
                            x: 16
                            width: parent.width - 48
                            text: MprisService.playerLabel(root.player)
                            customSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        SvgIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            icon: root.picking ? "chevron-down" : "chevron-up"
                            iconSize: 14
                            iconColor: SideState.fg
                            flat: true
                        }

                        HoverHandler {
                            id: selHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            enabled: MprisService.selectable.length > 0
                            onTapped: root.picking = !root.picking
                        }
                    }

                    Rectangle {
                        id: menu

                        anchors.bottom: selector.top
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width, 240)
                        height: menuCol.implicitHeight + 12
                        radius: 18
                        color: SideState.cardHi
                        border.width: 1
                        border.color: SideState.outline
                        opacity: root.picking ? 1 : 0
                        scale: root.picking ? 1 : 0.92
                        transformOrigin: Item.Bottom
                        visible: opacity > 0.01
                        z: 5

                        Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                        Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }

                        Column {
                            id: menuCol

                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2

                            Repeater {
                                model: MprisService.selectable

                                Rectangle {
                                    id: item

                                    required property var modelData
                                    readonly property bool current: modelData === root.player

                                    width: menuCol.width
                                    height: 34
                                    radius: 12
                                    color: current ? SideState.selected : (ih.hovered ? SideState.card : "transparent")

                                    SideText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: 12
                                        width: parent.width - 44
                                        text: MprisService.playerLabel(item.modelData)
                                        customSize: 12
                                        elide: Text.ElideRight
                                        color: item.current ? SideState.primary : SideState.fg
                                    }

                                    SvgIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        visible: item.current
                                        icon: "check"
                                        iconSize: 14
                                        iconColor: SideState.primary
                                        flat: true
                                    }

                                    HoverHandler {
                                        id: ih

                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    TapHandler {
                                        onTapped: {
                                            MprisService.selectPlayer(item.modelData);
                                            root.picking = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

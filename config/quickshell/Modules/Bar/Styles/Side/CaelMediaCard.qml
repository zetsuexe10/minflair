import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Dashboard media card, laid out like Caelestia's dash/Media: a wavy progress arc over the cover,
// title (primary), album (outline), artist (secondary) and three round buttons.
Item {
    id: root

    readonly property var player: MprisService.activePlayer
    readonly property real length: player && player.length > 0 && player.length < 100000 ? player.length : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, (player.position % length) / length)) : 0
    readonly property real sweep: 200
    readonly property real arcR: cover.width / 2 + 14

    implicitWidth: 230
    implicitHeight: 410

    // wavy progress arc, centred on the top of the cover
    Shape {
        id: arc

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        property real phase: 0

        NumberAnimation on phase {
            running: MprisService.isPlaying && root.visible
            from: 0
            to: Math.PI * 2
            duration: 2000
            loops: Animation.Infinite
        }

        ShapePath {
            strokeColor: Qt.rgba(SideState.fg.r, SideState.fg.g, SideState.fg.b, 0.14)
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: root.arcR
                radiusY: root.arcR
                startAngle: -90 - root.sweep / 2
                sweepAngle: root.sweep
            }
        }

        ShapePath {
            strokeColor: SideState.primary
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: {
                    const pts = [];
                    const total = root.sweep * root.progress;
                    const n = Math.max(2, Math.ceil(total / 3));
                    const cx = cover.x + cover.width / 2, cy = cover.y + cover.height / 2;
                    const amp = MprisService.isPlaying ? 2.6 : 0;
                    for (let i = 0; i <= n; i++) {
                        const deg = -90 - root.sweep / 2 + total * i / n;
                        const rad = deg * Math.PI / 180;
                        const r = root.arcR + amp * Math.sin(deg * 8 * Math.PI / 180 - arc.phase);
                        pts.push(Qt.point(cx + Math.cos(rad) * r, cy + Math.sin(rad) * r));
                    }
                    return pts;
                }
            }
        }
    }

    CaelCover {
        id: cover

        x: (root.width - width) / 2
        y: 34
        width: 148
        height: 148
        source: root.player ? (root.player.trackArtUrl || "") : ""
        playing: MprisService.isPlaying
    }

    ColumnLayout {
        anchors.top: cover.bottom
        anchors.topMargin: 26
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 4

        SideText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.player ? (root.player.trackTitle || "Unknown title") : "No media"
            color: SideState.primary
            customSize: 15
            font.bold: true
            elide: Text.ElideRight
        }

        SideText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.player ? (root.player.trackAlbum || "Unknown album") : "Play something in any player"
            color: SideState.muted
            customSize: 12
            elide: Text.ElideRight
        }

        SideText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.player !== null
            text: root.player ? (root.player.trackArtist || "Unknown artist") : ""
            color: SideState.secondary
            customSize: 13
            elide: Text.ElideRight
        }

        Item {
            Layout.fillHeight: true
        }

        CaelMediaControls {
            Layout.fillWidth: true
            compact: true
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

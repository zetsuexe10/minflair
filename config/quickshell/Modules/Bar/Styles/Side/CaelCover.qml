import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string source: ""
    property bool playing: false
    property bool visualiser: false
    readonly property int sides: 9
    readonly property real wobble: 0.05
    readonly property real maxBar: visualiser ? width * 0.15 : 0
    readonly property real gap: visualiser ? 8 : 0
    readonly property real coverR: width / 2 - maxBar - gap - (visualiser ? 2 : 0)
    property real spin: 0

    implicitWidth: 240
    implicitHeight: 240

    NumberAnimation on spin {
        running: root.playing && root.visible
        from: 0
        to: 360
        duration: 28000
        loops: Animation.Infinite
    }

    Canvas {
        id: ring

        anchors.fill: parent
        visible: root.visualiser
        renderTarget: Canvas.FramebufferObject
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.visualiser)
                return;
            const n = CavaService.bars;
            const cx = width / 2, cy = height / 2;
            const a = root.spin * Math.PI / 180;
            ctx.lineCap = "round";
            ctx.lineWidth = Math.max(3, (2 * Math.PI * root.coverR) / n * 0.55);
            ctx.strokeStyle = SideState.primary;
            for (let i = 0; i < n; i++) {
                const th = i * 2 * Math.PI / n - Math.PI / 2;
                const edge = root.coverR * ((1 - root.wobble) + root.wobble * Math.cos(root.sides * (th - a)));
                const r0 = edge + root.gap + 3;
                const v = Math.max(0.02, CavaService.values[i] || 0);
                const r1 = r0 + v * (root.maxBar - 4);
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(th) * r0, cy + Math.sin(th) * r0);
                ctx.lineTo(cx + Math.cos(th) * r1, cy + Math.sin(th) * r1);
                ctx.stroke();
            }
        }

        Connections {
            target: CavaService
            function onValuesChanged() { ring.requestPaint(); }
        }

        Connections {
            target: root
            function onSpinChanged() { if (!CavaService.wanted) ring.requestPaint(); }
        }
    }

    Item {
        id: cover

        anchors.centerIn: parent
        width: root.coverR * 2
        height: width

        Rectangle {
            id: backdrop

            anchors.fill: parent
            color: SideState.cardHi
            visible: false
        }

        Item {
            id: maskSrc

            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true

            Shape {
                anchors.fill: parent
                rotation: root.spin
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"

                    PathPolyline {
                        path: {
                            const pts = [];
                            const R = cover.width / 2;
                            for (let i = 0; i <= 240; i++) {
                                const th = i * 2 * Math.PI / 240;
                                const r = R * ((1 - root.wobble) + root.wobble * Math.cos(root.sides * th));
                                pts.push(Qt.point(R + Math.cos(th) * r, R + Math.sin(th) * r));
                            }
                            return pts;
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskSrc
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Rectangle {
                anchors.fill: parent
                color: SideState.cardHi
            }

            Image {
                id: art

                anchors.fill: parent
                source: root.source
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(560, 560)
                asynchronous: true
                visible: status === Image.Ready
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            SvgIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                icon: "music"
                iconSize: Math.round(parent.width * 0.32)
                iconColor: SideState.muted
                flat: true
            }
        }
    }
}

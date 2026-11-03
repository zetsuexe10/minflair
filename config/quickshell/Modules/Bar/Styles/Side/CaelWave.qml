import QtQuick
import QtQuick.Shapes
import qs.Core

// A sine wave that travels while playing. Straight (amplitude 0) when paused. Draws from x=0 to `length`.
Shape {
    id: root

    property real length: width
    property real amplitude: 3
    property real wavelength: 22
    property color color: SideState.primary
    property real thickness: 4
    property bool running: true
    property real phase: 0
    readonly property real amp: running ? amplitude : 0

    preferredRendererType: Shape.CurveRenderer

    NumberAnimation on phase {
        running: root.running && root.visible
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }

    ShapePath {
        strokeColor: root.color
        strokeWidth: root.thickness
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin

        PathPolyline {
            path: {
                const pts = [];
                const n = Math.max(2, Math.ceil(root.length / 3));
                for (let i = 0; i <= n; i++) {
                    const x = root.length * i / n;
                    pts.push(Qt.point(x, root.height / 2 + root.amp * Math.sin(x / root.wavelength * 6.2832 - root.phase)));
                }
                return pts;
            }
        }
    }
}

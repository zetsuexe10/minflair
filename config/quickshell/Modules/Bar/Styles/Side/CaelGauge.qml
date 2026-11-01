import QtQuick
import QtQuick.Shapes
import qs.Core

// Circular progress ring with the content centred inside, as in Caelestia's resources card.
Item {
    id: root

    property real value: 0                 // 0..1
    property color fg: Theme.accent
    property color track: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)
    property real stroke: 6
    default property alias contents: holder.data
    readonly property real v: Math.max(0, Math.min(1, value))
    readonly property real rad: (Math.min(width, height) - stroke) / 2

    implicitWidth: 64
    implicitHeight: 64

    Behavior on value { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.track
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.rad
                radiusY: root.rad
                startAngle: -90
                sweepAngle: 359.9
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fg
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.rad
                radiusY: root.rad
                startAngle: -90
                sweepAngle: 359.9 * root.v
            }
        }
    }

    Item {
        id: holder

        anchors.fill: parent
    }
}

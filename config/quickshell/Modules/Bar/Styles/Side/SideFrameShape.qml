import QtQuick
import QtQuick.Shapes

// Solid frame: the whole item minus a rounded rectangle inset by left/top/right/bottom.
Item {
    id: root

    property real insetLeft: 10
    property real insetRight: 10
    property real insetTop: 10
    property real insetBottom: 10
    property real rounding: 24
    property color fill: "#222"

    readonly property real r: Math.max(0, Math.min(rounding, (width - insetLeft - insetRight) / 2, (height - insetTop - insetBottom) / 2))
    readonly property real x0: insetLeft
    readonly property real y0: insetTop
    readonly property real x1: width - insetRight
    readonly property real y1: height - insetBottom

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fill
            strokeColor: "transparent"
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill

            PathSvg {
                path: "M0,0 H" + root.width + " V" + root.height + " H0 Z " + "M" + (root.x0 + root.r) + "," + root.y0 + " H" + (root.x1 - root.r) + " A" + root.r + "," + root.r + " 0 0 1 " + root.x1 + "," + (root.y0 + root.r) + " V" + (root.y1 - root.r) + " A" + root.r + "," + root.r + " 0 0 1 " + (root.x1 - root.r) + "," + root.y1 + " H" + (root.x0 + root.r) + " A" + root.r + "," + root.r + " 0 0 1 " + root.x0 + "," + (root.y1 - root.r) + " V" + (root.y0 + root.r) + " A" + root.r + "," + root.r + " 0 0 1 " + (root.x0 + root.r) + "," + root.y0 + " Z"
            }
        }
    }
}

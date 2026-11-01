import QtQuick
import QtQuick.Shapes

// Background of a panel that grows out of a screen edge: flat on the frame, rounded on the free
// corners, with concave fillets where it meets the frame. `edge` is the screen edge it is attached to.
// The shape fills this item, which must be `2 * r` wider (top/bottom) or taller (left/right) than the body.
Item {
    id: root

    property string edge: "top"     // top, bottom, left, right
    property real rounding: 24
    property color fill: "#222"
    readonly property bool alongX: edge === "top" || edge === "bottom"
    // length along the edge and depth into the screen
    readonly property real a: alongX ? width : height
    readonly property real d: alongX ? height : width
    readonly property real r: Math.max(0, Math.min(rounding, d / 2, a / 4))

    // outline of a panel attached to the top edge, in local (u along, v depth) coordinates
    function seg(u, v) {
        switch (edge) {
        case "top": return u + "," + v;
        case "bottom": return u + "," + (d - v);
        case "left": return v + "," + u;
        default: return (d - v) + "," + u;
        }
    }

    // reflections (bottom, left) turn arcs the other way round
    readonly property int sw: (edge === "top" || edge === "right") ? 1 : 0
    readonly property int cc: 1 - sw

    readonly property string outline: {
        const r = root.r, A = a, D = d;
        let p = "M" + seg(0, 0);
        p += " L" + seg(A, 0);
        p += " A" + r + "," + r + " 0 0 " + cc + " " + seg(A - r, r);
        p += " L" + seg(A - r, D - r);
        p += " A" + r + "," + r + " 0 0 " + sw + " " + seg(A - 2 * r, D);
        p += " L" + seg(2 * r, D);
        p += " A" + r + "," + r + " 0 0 " + sw + " " + seg(r, D - r);
        p += " L" + seg(r, r);
        p += " A" + r + "," + r + " 0 0 " + cc + " " + seg(0, 0);
        return p + " Z";
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fill
            strokeColor: "transparent"
            strokeWidth: -1

            PathSvg {
                path: root.outline
            }
        }
    }
}

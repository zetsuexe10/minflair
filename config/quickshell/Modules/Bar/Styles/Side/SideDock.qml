import QtQuick
import qs.Core
import qs.Core.Components

// A panel that grows out of a screen edge. With `attached` it shares the frame's colour and has
// concave fillets where it meets it; otherwise it is a floating rounded card. Lives inside a
// clipped `stage` item that covers the free area (the screen minus the frame), so sliding out
// simply disappears behind the frame.
Item {
    id: root

    property string edge: "right"        // screen edge the dock grows from: left, right, top, bottom
    property bool open: false
    property bool attached: true
    property real rounding: 24
    property real padding: 16
    property real margin: 24             // keep this far from the stage corners along the edge
    property real center: -1             // wanted centre along the edge, in stage coordinates; -1 = use align
    property string align: "center"      // start, center, end
    property real contentWidth: 0
    property real contentHeight: 0
    property real gap: 4                 // distance from the edge when floating
    property real prog: open ? 1 : 0
    default property alias contents: body.data
    readonly property bool alongX: edge === "top" || edge === "bottom"
    readonly property real stageW: parent ? parent.width : 0
    readonly property real stageH: parent ? parent.height : 0
    readonly property real fillet: attached ? Math.min(rounding, 24) : 0
    readonly property real bw: Math.max(1, Math.min(contentWidth + padding * 2, stageW - (alongX ? margin * 2 + fillet * 2 : gap + 8)))
    readonly property real bh: Math.max(1, Math.min(contentHeight + padding * 2, stageH - (alongX ? gap + 8 : margin * 2 + fillet * 2)))
    readonly property real total: (alongX ? bw : bh) + fillet * 2
    readonly property real span: alongX ? stageW : stageH
    readonly property real along: {
        const lo = margin;
        const hi = Math.max(lo, span - margin - total);
        let p;
        if (center >= 0)
            p = center - total / 2;
        else if (align === "start")
            p = lo;
        else if (align === "end")
            p = hi;
        else
            p = (span - total) / 2;
        return Math.max(lo, Math.min(hi, p));
    }
    readonly property real offset: attached ? 0 : gap
    readonly property real depth: alongX ? bh : bw
    // window-space rectangle the dock covers while shown (for the input mask)
    readonly property bool shown: prog > 0.01

    width: alongX ? total : bw
    height: alongX ? bh : total
    visible: shown
    opacity: Math.min(1, prog * 1.6)
    x: {
        if (edge === "left")
            return offset - (1 - prog) * (bw + offset);
        if (edge === "right")
            return stageW - bw - offset + (1 - prog) * (bw + offset);
        return along;
    }
    y: {
        if (edge === "top")
            return offset - (1 - prog) * (bh + offset);
        if (edge === "bottom")
            return stageH - bh - offset + (1 - prog) * (bh + offset);
        return along;
    }

    Behavior on prog { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
    Behavior on contentHeight { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
    Behavior on contentWidth { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }

    SideAttachedShape {
        anchors.fill: parent
        visible: root.attached
        edge: root.edge
        rounding: root.rounding
        fill: Theme.opaqueBg
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.attached
        radius: root.rounding
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
    }

    Item {
        id: body

        x: root.alongX ? root.fillet : 0
        y: root.alongX ? 0 : root.fillet
        width: root.bw
        height: root.bh
    }

    // swallow clicks so the click-outside area behind does not close the panel
    MouseArea {
        anchors.fill: body
        z: -1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
    }
}

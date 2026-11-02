import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Workspace switcher in Caelestia's manner: a pill that stretches while it slides (the leading edge
// moves first, the trailing edge 1.5x slower), labels that invert inside the pill, and background
// capsules behind occupied workspaces that merge with occupied neighbours.
SidePill {
    id: root

    property bool vertical: true
    readonly property int slot: 24
    readonly property int gap: 4
    readonly property int pad: 5
    readonly property string display: SettingsService.sideCfg("workspaceStyle")      // "numbers" | "dots"
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // fixed number of slots: scrolling never changes the bar length, the window of ids follows the active one
    readonly property int shown: Math.min(SettingsService.numberOfWorkspaces, 5)
    readonly property int first: Math.max(1, Math.min(SettingsService.numberOfWorkspaces - shown + 1, activeWsId - Math.floor(shown / 2)))
    readonly property real along: shown * slot + (shown - 1) * gap + pad * 2
    readonly property real step: slot + gap
    readonly property var occ: {
        const r = [];
        for (let i = 0; i < shown; i++)
            r.push(occupied(first + i));
        return r;
    }

    // app class of the first window on each shown workspace (for the icons style)
    readonly property var classes: {
        const r = [];
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < shown; i++) {
            let cls = "";
            for (let k = 0; k < list.length; k++) {
                const ws = list[k];
                if (ws && ws.id === first + i && ws.toplevels && ws.toplevels.values.length > 0) {
                    const tl = ws.toplevels.values[0];
                    cls = (tl && tl.lastIpcObject && tl.lastIpcObject.class) ? String(tl.lastIpcObject.class) : "";
                }
            }
            r.push(cls);
        }
        return r;
    }

    // Caelestia's expressive spatial curve (slight overshoot)
    readonly property var spatial: [0.38, 1.21, 0.22, 1.0, 1.0, 1.0]
    readonly property int leadMs: 320
    readonly property int trailMs: Math.round(leadMs * 1.5)

    function occupied(id) {
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            if (ws && ws.id === id)
                return ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0;
        }
        return false;
    }

    function go(id) {
        if (id >= 1 && id <= SettingsService.numberOfWorkspaces)
            Hyprland.dispatch('hl.dsp.focus({workspace=' + id + '})');
    }

    implicitWidth: vertical ? SideState.railSize : along
    implicitHeight: vertical ? along : SideState.railSize

    // ---- sliding pill edges ----------------------------------------------------------------
    readonly property real target: pad + Math.max(0, Math.min(shown - 1, activeWsId - first)) * step
    property real edgeA: target
    property real edgeB: target + slot

    Behavior on edgeA { NumberAnimation { id: animA; duration: root.edgeA > root.target ? root.leadMs : root.trailMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    Behavior on edgeB { NumberAnimation { id: animB; duration: root.edgeB > root.target + root.slot ? root.trailMs : root.leadMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    onTargetChanged: { edgeA = target; edgeB = target + slot; }

    // ---- occupied backgrounds (merge with occupied neighbours) ----------------------------
    Item {
        x: root.vertical ? (root.width - root.slot) / 2 : root.pad
        y: root.vertical ? root.pad : (root.height - root.slot) / 2

        Repeater {
            model: root.shown

            Rectangle {
                id: bg

                required property int index
                readonly property bool occ: root.occ[index] === true
                readonly property bool prevOcc: index > 0 && root.occ[index - 1] === true
                readonly property bool nextOcc: index < root.shown - 1 && root.occ[index + 1] === true
                property real leadR: (occ && prevOcc) ? 0 : root.slot / 2
                property real trailR: (occ && nextOcc) ? 0 : root.slot / 2
                property real leadPad: (occ && prevOcc) ? root.gap : 0
                property real trailPad: (occ && nextOcc) ? root.gap : 0

                x: root.vertical ? 0 : index * root.step - leadPad
                y: root.vertical ? index * root.step - leadPad : 0
                width: root.vertical ? root.slot : root.slot + leadPad + trailPad
                height: root.vertical ? root.slot + leadPad + trailPad : root.slot
                topLeftRadius: leadR
                topRightRadius: root.vertical ? leadR : trailR
                bottomLeftRadius: root.vertical ? trailR : leadR
                bottomRightRadius: trailR
                color: SideState.cardHi
                opacity: occ ? 1 : 0

                Behavior on leadR { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on trailR { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on leadPad { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on trailPad { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 220 } }
            }
        }
    }

    // ---- labels: one layer in the normal colour, one inverted inside the pill -------------
    component Labels: Item {
        id: lab

        property bool inverted: false

        width: root.vertical ? root.slot : root.along - root.pad * 2
        height: root.vertical ? root.along - root.pad * 2 : root.slot

        Repeater {
            model: root.shown

            Item {
                id: it

                required property int index
                readonly property int wsId: root.first + index
                readonly property bool isActive: wsId === root.activeWsId
                readonly property bool isOcc: root.occ[index] === true
                property color col: lab.inverted ? SideState.primaryText : (isOcc ? SideState.fg : SideState.muted)

                x: root.vertical ? 0 : index * root.step
                y: root.vertical ? index * root.step : 0
                width: root.slot
                height: root.slot

                readonly property string appIcon: root.display === "icons" && it.isOcc ? Quickshell.iconPath(root.classes[index].toLowerCase(), true) : ""

                // app icon of the workspace's first window (falls back to the number)
                Image {
                    anchors.centerIn: parent
                    visible: it.appIcon !== ""
                    width: 17
                    height: 17
                    source: it.appIcon
                    sourceSize: Qt.size(34, 34)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }

                // numbers
                SideText {
                    anchors.centerIn: parent
                    visible: (root.display === "numbers" || root.display === "icons") && it.appIcon === "" && (it.isActive || it.isOcc || lab.inverted)
                    text: it.wsId
                    customSize: 13
                    font.bold: true
                    color: it.col
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: (root.display === "numbers" || root.display === "icons") && it.appIcon === "" && !(it.isActive || it.isOcc || lab.inverted)
                    width: 6
                    height: 6
                    radius: 3
                    color: it.col
                }

                // dots: empty = small circle, occupied = rounded square, active = larger disc
                Rectangle {
                    id: dot

                    anchors.centerIn: parent
                    visible: root.display === "dots"
                    width: it.isActive ? 14 : (it.isOcc ? 10 : 6)
                    height: width
                    radius: it.isOcc && !it.isActive ? 3 : width / 2
                    color: it.col

                    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
                    Behavior on radius { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Behavior on col { ColorAnimation { duration: 200 } }
            }
        }
    }

    Item {
        id: grid

        x: root.vertical ? (root.width - root.slot) / 2 : root.pad
        y: root.vertical ? root.pad : (root.height - root.slot) / 2
        width: root.vertical ? root.slot : root.along - root.pad * 2
        height: root.vertical ? root.along - root.pad * 2 : root.slot

        Labels {}

        // hover + click targets
        Repeater {
            model: root.shown

            Item {
                id: hit

                required property int index

                x: root.vertical ? 0 : index * root.step
                y: root.vertical ? index * root.step : 0
                width: root.slot
                height: root.slot
                scale: ma.pressed ? 0.86 : (ma.containsMouse ? 1.1 : 1)

                Behavior on scale { SpringAnimation { spring: 3.4; damping: 0.3; epsilon: 0.002 } }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: SideState.card
                    opacity: (ma.containsMouse && root.first + hit.index !== root.activeWsId) ? 0.9 : 0
                    z: -1

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    id: ma

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(root.first + hit.index)
                }
            }
        }
    }

    // the pill: clips an inverted copy of the labels so the glyph under it flips colour while it slides
    Item {
        id: ind

        x: root.vertical ? (root.width - root.slot) / 2 : root.edgeA
        y: root.vertical ? root.edgeA : (root.height - root.slot) / 2
        width: root.vertical ? root.slot : root.edgeB - root.edgeA
        height: root.vertical ? root.edgeB - root.edgeA : root.slot
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: root.slot / 2
            color: SideState.primary
        }

        Item {
            x: grid.x - ind.x
            y: grid.y - ind.y
            width: grid.width
            height: grid.height

            Labels { inverted: true }
        }

        // clicks fall through to the slots below
        enabled: false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        enabled: SettingsService.sideCfg("scroll", "workspaces")
        onWheel: (wheel) => root.go(root.activeWsId + (wheel.angleDelta.y > 0 ? -1 : 1))
    }
}

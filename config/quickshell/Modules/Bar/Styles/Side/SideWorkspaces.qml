import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Workspace switcher in Caelestia's manner: a pill that stretches while it slides (the leading edge
// moves first, the trailing edge 1.5x slower), labels that invert inside the pill, capsules behind
// occupied workspaces that merge with occupied neighbours, and in "icons" style the app icons of each
// workspace's windows listed under it, the workspace expanding smoothly to make room.
SidePill {
    id: root

    property bool vertical: true
    readonly property int slot: 24
    readonly property int gap: 4
    readonly property int pad: 5
    readonly property int maxIcons: 3
    readonly property int iconSize: 16
    readonly property string display: SettingsService.sideCfg("workspaceStyle") === "numbers" ? "numbers" : (SettingsService.sideCfg("workspaceStyle") === "icons" ? "icons" : "shapes")   // shapes | numbers | icons
    readonly property bool shapes: display === "shapes"
    // the focused workspace takes a new random shape each time, like Caelestia's Material shapes
    readonly property var shapeSet: [{ "n": 6, "a": 0.14 }, { "n": 9, "a": 0.08 }, { "n": 4, "a": 0.22 }, { "n": 3, "a": 0.2 }, { "n": 8, "a": 0.17 }, { "n": 5, "a": 0.13 }, { "n": 2, "a": 0.16 }, { "n": 7, "a": 0.1 }, { "n": 0, "a": 0 }]
    property int shapeIdx: 0
    readonly property bool withIcons: display === "icons"
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // fixed number of slots: scrolling never changes the id window size, it just follows the active one
    readonly property int shown: Math.min(SettingsService.numberOfWorkspaces, 5)
    readonly property int first: Math.max(1, Math.min(SettingsService.numberOfWorkspaces - shown + 1, activeWsId - Math.floor(shown / 2)))
    readonly property int activeIdx: Math.max(0, Math.min(shown - 1, activeWsId - first))

    // Caelestia's expressive spatial curve (slight overshoot)
    readonly property var spatial: [0.38, 1.21, 0.22, 1.0, 1.0, 1.0]
    readonly property int leadMs: 320
    readonly property int trailMs: Math.round(leadMs * 1.5)

    // ---- data: occupancy and the windows' app classes per shown workspace -------------------
    readonly property var wins: {
        const r = [];
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < shown; i++) {
            const classes = [];
            for (let k = 0; k < list.length; k++) {
                const ws = list[k];
                if (ws && ws.id === first + i && ws.toplevels) {
                    const tls = ws.toplevels.values;
                    for (let j = 0; j < tls.length; j++) {
                        const tl = tls[j];
                        let cls = (tl && tl.lastIpcObject && tl.lastIpcObject.class) ? String(tl.lastIpcObject.class) : ((tl && tl.wayland && tl.wayland.appId) ? String(tl.wayland.appId) : "");
                        classes.push(cls);
                    }
                }
            }
            r.push(classes);
        }
        return r;
    }
    readonly property var occ: wins.map(w => w.length > 0)

    // icon file for an app class: icon theme by name first, then through its desktop entry
    function iconFor(cls) {
        if (!cls)
            return "";
        let p = Quickshell.iconPath(cls.toLowerCase(), true);
        if (p !== "")
            return p;
        const e = DesktopEntries.heuristicLookup(cls);
        if (e && e.icon) {
            p = Quickshell.iconPath(e.icon, true);
            if (p !== "")
                return p;
            if (e.icon.indexOf("/") === 0)
                return "file://" + e.icon;
        }
        return "";
    }

    function go(id) {
        if (id >= 1 && id <= SettingsService.numberOfWorkspaces)
            Hyprland.dispatch('hl.dsp.focus({workspace=' + id + '})');
    }

    // ---- per-slot extent (number + window icons), animated ----------------------------------
    function wantedExt(i) {
        const n = (withIcons && i < shown) ? Math.min(maxIcons, wins[i].length) : 0;
        return slot + (n > 0 ? n * (iconSize + 2) + 2 : 0);
    }

    property real e0: wantedExt(0)
    property real e1: wantedExt(1)
    property real e2: wantedExt(2)
    property real e3: wantedExt(3)
    property real e4: wantedExt(4)

    Behavior on e0 { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    Behavior on e1 { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    Behavior on e2 { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    Behavior on e3 { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    Behavior on e4 { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }

    function ext(i) {
        return [e0, e1, e2, e3, e4][i];
    }

    function off(i) {
        let o = pad;
        for (let k = 0; k < i; k++)
            o += ext(k) + gap;
        return o;
    }

    readonly property real along: off(shown) - gap + pad

    implicitWidth: vertical ? SideState.railSize : along
    implicitHeight: vertical ? along : SideState.railSize

    // ---- sliding pill edges ------------------------------------------------------------------
    readonly property real tA: off(activeIdx)
    readonly property real tB: tA + ext(activeIdx)
    property real edgeA: tA
    property real edgeB: tB
    property bool sliding: false
    property int lastIdx: activeIdx

    Behavior on edgeA { enabled: root.sliding; NumberAnimation { duration: root.edgeA > root.tA ? root.leadMs : root.trailMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
    Behavior on edgeB { enabled: root.sliding; NumberAnimation { duration: root.edgeB > root.tB ? root.trailMs : root.leadMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }

    // a workspace change slides (stretches) the pill; layout growth only drags it along
    function follow() {
        if (activeIdx !== lastIdx) {
            lastIdx = activeIdx;
            sliding = true;
            slideTimer.restart();
        }
        edgeA = tA;
        edgeB = tB;
    }
    onTAChanged: follow()
    onTBChanged: follow()

    Timer {
        id: slideTimer

        interval: 600
        onTriggered: root.sliding = false
    }

    // window classes only exist once Hyprland has been asked for them
    Timer {
        interval: 1500
        running: root.withIcons
        repeat: true
        triggeredOnStart: true
        onTriggered: Hyprland.refreshToplevels()
    }

    onActiveWsIdChanged: {
        shapeIdx = Math.floor(Math.random() * shapeSet.length);
        if (withIcons)
            Hyprland.refreshToplevels();
    }

    // an n-lobed rounded shape (flower, cookie, clover, gem...) drawn as a closed polyline
    component Glyph: Item {
        id: gl

        property real size: 16
        property int lobes: 6
        property real amp: 0.14
        property color color: "white"
        readonly property var pts: {
            const r = [];
            const N = 72;
            for (let i = 0; i < N; i++) {
                const th = 2 * Math.PI * i / N;
                const rad = 0.5 * (1 + amp * Math.cos(lobes * th)) / (1 + amp);
                r.push(Qt.point(size / 2 + rad * size * Math.cos(th), size / 2 + rad * size * Math.sin(th)));
            }
            return r;
        }

        width: size
        height: size
        onLobesChanged: pop.restart()

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: gl.color
                strokeColor: "transparent"

                PathPolyline {
                    path: gl.pts
                }
            }
        }

        ParallelAnimation {
            id: pop

            NumberAnimation { target: gl; property: "scale"; from: 0.45; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            NumberAnimation { target: gl; property: "rotation"; from: -70; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    // ---- occupied backgrounds (merge with occupied neighbours) ----------------------------
    Item {
        x: root.vertical ? (root.width - root.slot) / 2 : 0
        y: root.vertical ? 0 : (root.height - root.slot) / 2

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
                readonly property real start: root.off(index) - leadPad
                readonly property real length: root.ext(index) + leadPad + trailPad

                x: root.vertical ? 0 : start
                y: root.vertical ? start : 0
                width: root.vertical ? root.slot : length
                height: root.vertical ? length : root.slot
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

        width: root.vertical ? root.slot : root.along
        height: root.vertical ? root.along : root.slot

        Repeater {
            model: root.shown

            Item {
                id: it

                required property int index
                readonly property int wsId: root.first + index
                readonly property bool isActive: wsId === root.activeWsId
                readonly property bool isOcc: root.occ[index] === true
                property color col: lab.inverted ? SideState.primaryText : (isOcc ? SideState.fg : SideState.muted)
                readonly property var shownWins: root.withIcons ? root.wins[index].slice(0, root.maxIcons) : []

                x: root.vertical ? 0 : root.off(index)
                y: root.vertical ? root.off(index) : 0
                width: root.vertical ? root.slot : root.ext(index)
                height: root.vertical ? root.ext(index) : root.slot

                Behavior on col { ColorAnimation { duration: 200 } }

                // the workspace mark sits at the start of the slot
                Item {
                    width: root.slot
                    height: root.slot

                    SideText {
                        anchors.centerIn: parent
                        visible: !root.shapes && (it.isActive || it.isOcc || lab.inverted)
                        text: it.wsId
                        customSize: 13
                        font.bold: true
                        color: it.col
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: !root.shapes && !(it.isActive || it.isOcc || lab.inverted)
                        width: 6
                        height: 6
                        radius: 3
                        color: it.col
                    }

                    // shapes: empty = small circle, occupied = rounded square, focused = a random lobed shape
                    Rectangle {
                        anchors.centerIn: parent
                        visible: root.shapes && !it.isActive
                        width: it.isOcc ? 10 : 6
                        height: width
                        radius: it.isOcc ? 3 : width / 2
                        color: it.col

                        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spatial } }
                        Behavior on radius { NumberAnimation { duration: 200 } }
                    }

                    Glyph {
                        anchors.centerIn: parent
                        visible: root.shapes && it.isActive
                        size: 17
                        lobes: root.shapeSet[root.shapeIdx].n
                        amp: root.shapeSet[root.shapeIdx].a
                        color: it.col
                    }
                }

                // app icons of the workspace's windows, listed after the mark
                Repeater {
                    model: it.shownWins

                    Item {
                        id: wi

                        required property int index
                        required property string modelData
                        readonly property string src: root.iconFor(modelData)

                        x: root.vertical ? (root.slot - root.iconSize) / 2 : root.slot + 2 + index * (root.iconSize + 2)
                        y: root.vertical ? root.slot + 2 + index * (root.iconSize + 2) : (root.slot - root.iconSize) / 2
                        width: root.iconSize
                        height: root.iconSize
                        opacity: root.ext(it.index) > root.slot + 4 ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Image {
                            anchors.fill: parent
                            visible: wi.src !== ""
                            source: wi.src
                            sourceSize: Qt.size(32, 32)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                        }

                        // no icon found: a small dot for the window
                        Rectangle {
                            anchors.centerIn: parent
                            visible: wi.src === ""
                            width: 6
                            height: 6
                            radius: 3
                            color: it.col
                        }
                    }
                }
            }
        }
    }

    Item {
        id: grid

        x: root.vertical ? (root.width - root.slot) / 2 : 0
        y: root.vertical ? 0 : (root.height - root.slot) / 2
        width: root.vertical ? root.slot : root.along
        height: root.vertical ? root.along : root.slot

        Labels {}

        // hover + click targets cover the whole slot, icons included
        Repeater {
            model: root.shown

            Item {
                id: hit

                required property int index

                x: root.vertical ? 0 : root.off(index)
                y: root.vertical ? root.off(index) : 0
                width: root.vertical ? root.slot : root.ext(index)
                height: root.vertical ? root.ext(index) : root.slot

                Rectangle {
                    anchors.fill: parent
                    radius: root.slot / 2
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
        enabled: false

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
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        enabled: SettingsService.sideCfg("scroll", "workspaces")
        onWheel: (wheel) => root.go(root.activeWsId + (wheel.angleDelta.y > 0 ? -1 : 1))
    }
}

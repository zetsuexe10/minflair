import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Bar 4: a floating dynamic island on any edge. At rest it is a small capsule that morphs between
// the time, the workspaces and the active window (workspaces pop in whenever you switch). Hovering
// grows it into the full bar; Shell settings > Pill can keep it expanded. Only the capsule takes
// input: the surface itself is transparent and reserves no space.
PanelWindow {
    id: root

    required property var notificationService

    readonly property string position: SettingsService.sideBarPosition
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int railSize: SideState.railSize
    readonly property int thickMax: railSize + 8                    // capsule thickness when open
    readonly property int thickMin: railSize + 2                    // ...and at rest
    readonly property int gapEdge: SideState.islandGap
    readonly property string align: SideState.islandAlign
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "pill" && !DisplayProfileService.gameModeActive
    readonly property bool shown: isActive && !HyprlandService.isTrueFullscreen
    readonly property bool pinned: SettingsService.sideCfg("pinned") === true
    readonly property string idleView: SettingsService.sideCfg("idle") || "time"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-pill-bar"
    WlrLayershell.exclusiveZone: 0
    color: "transparent"
    focusable: false
    visible: SettingsService.settingsLoaded
    implicitWidth: vertical ? thickMax + gapEdge * 2 : 0
    implicitHeight: vertical ? 0 : thickMax + gapEdge * 2

    anchors {
        top: root.vertical || root.position === "top"
        bottom: root.vertical || root.position === "bottom"
        left: !root.vertical || root.position === "left"
        right: !root.vertical || root.position === "right"
    }

    // only the capsule takes input
    mask: Region {
        x: root.shown ? pill.x : 0
        y: root.shown ? pill.y : 0
        width: root.shown ? pill.width : 0
        height: root.shown ? pill.height : 0
    }

    Item {
        id: pill

        readonly property real total: root.vertical ? root.height : root.width
        readonly property bool wide: root.pinned || hover.hovered || root.keepOpen
        // the small capsule hugs whatever it currently shows
        readonly property real compactLen: Math.max(root.thickMax * 2, slot.viewLen + 28)
        readonly property real fullLen: Math.min(total - 24, (full.implicitWidth > 0 ? (root.vertical ? full.implicitHeight : full.implicitWidth) : 0) + 24)
        property real len: wide ? Math.max(fullLen, compactLen) : compactLen
        property real thick: wide ? root.thickMax : root.thickMin

        function along() {
            const m = SideState.islandOffset;
            if (root.align === "start")
                return m;
            if (root.align === "end")
                return total - len - m;
            return (total - len) / 2;
        }

        // the capsule stays put along the edge while its length springs
        // thickness grows a little when it opens, centred in the band so the edge gap stays even
        readonly property real band: root.thickMax + root.gapEdge * 2

        x: root.vertical ? (root.position === "left" ? root.gapEdge : root.width - root.gapEdge - root.thickMax) + (root.thickMax - thick) / 2 : along()
        y: root.vertical ? along() : (root.position === "top" ? root.gapEdge : root.height - root.gapEdge - root.thickMax) + (root.thickMax - thick) / 2
        width: root.vertical ? thick : len
        height: root.vertical ? len : thick
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        transform: Translate {
            readonly property real hidden: root.shown ? 0 : -(root.thickMax + root.gapEdge)
            x: root.vertical ? (root.position === "left" ? hidden : -hidden) : 0
            y: root.vertical ? 0 : (root.position === "top" ? hidden : -hidden)

            Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
            Behavior on y { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
        }

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on len { SpringAnimation { spring: 3.4; damping: 0.5; epsilon: 0.3 } }
        Behavior on thick { SpringAnimation { spring: 4; damping: 0.55; epsilon: 0.2 } }

        HoverHandler {
            id: hover

            onHoveredChanged: {
                if (hovered)
                    root.keepOpen = true;
                else
                    collapseTimer.restart();
            }
        }

        Timer {
            id: collapseTimer

            interval: 450
            onTriggered: {
                if (SideState.popout !== "" || AppState.activeWidget !== "")
                    restart();
                else
                    root.keepOpen = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: SideState.surface
            border.width: 1
            border.color: SideState.outline
        }

        // volume on the first half, brightness on the second, like the side bar
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                const frac = root.vertical ? wheel.y / height : wheel.x / width;
                const dir = wheel.angleDelta.y > 0 ? 1 : -1;
                if (frac < 0.5) {
                    if (SettingsService.sideCfg("scroll", "volume"))
                        SideState.nudgeVolume(dir);
                } else if (SettingsService.sideCfg("scroll", "brightness") && SideState.brightnessAvailable) {
                    SideState.nudgeBrightness(dir);
                }
            }
        }

        // ---- small capsule: one view at a time, crossfading --------------------------------------
        Item {
            id: slot

            // time | workspaces | window; workspaces take over for a moment when you switch
            readonly property string view: root.peek ? "workspaces" : root.idleView
            readonly property real viewLen: view === "workspaces" ? (root.vertical ? ws.implicitHeight : ws.implicitWidth)
                : view === "window" ? (root.vertical ? 120 : 190) : (root.vertical ? clk.implicitHeight : clk.implicitWidth)

            anchors.centerIn: parent
            width: root.vertical ? root.railSize : viewLen
            height: root.vertical ? viewLen : root.railSize
            opacity: pill.wide ? 0 : 1
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
            Behavior on width { enabled: !root.vertical; NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: root.vertical; NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

            SideClock {
                id: clk

                anchors.centerIn: parent
                vertical: root.vertical
                color: "transparent"
                border.width: 0
                opacity: slot.view === "time" ? 1 : 0
                scale: slot.view === "time" ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
            }

            SideWorkspaces {
                id: ws

                anchors.centerIn: parent
                vertical: root.vertical
                color: "transparent"
                border.width: 0
                opacity: slot.view === "workspaces" ? 1 : 0
                scale: slot.view === "workspaces" ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
            }

            SideActiveWindow {
                anchors.centerIn: parent
                width: root.vertical ? root.railSize : parent.width
                height: root.vertical ? parent.height : root.railSize
                vertical: root.vertical
                opacity: slot.view === "window" ? 1 : 0
                scale: slot.view === "window" ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
            }
        }

        // ---- full bar ----------------------------------------------------------------------------
        GridLayout {
            id: full

            anchors.centerIn: parent
            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: root.vertical ? 99 : 1
            columns: root.vertical ? 1 : 99
            rowSpacing: 6
            columnSpacing: 6
            opacity: pill.wide ? 1 : 0
            visible: opacity > 0.01 && root.isActive

            Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }

            SideButton {
                visible: SettingsService.sideCfg("entries", "logo")
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.railSize
                Layout.preferredHeight: root.railSize
                size: root.railSize
                icon: "apps-filled"
                iconColor: SideState.primary
                iconSize: Constants.sizeXl
                active: AppState.isWidgetOpen("launcher")
                onClicked: AppState.toggleWidget("launcher")

                SidePill {
                    z: -1
                    anchors.fill: parent
                    radius: width / 2
                }
            }

            SideWorkspaces {
                visible: SettingsService.sideCfg("entries", "workspaces")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideActiveWindow {
                visible: SettingsService.sideCfg("entries", "activeWindow")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.vertical ? root.railSize : 170
                Layout.preferredHeight: root.vertical ? 120 : root.railSize
            }

            SideTray {
                visible: SettingsService.sideCfg("entries", "tray")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideStatus {
                visible: SettingsService.sideCfg("entries", "statusIcons")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
                notificationService: root.notificationService
            }

            SideClock {
                visible: SettingsService.sideCfg("entries", "clock")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideButton {
                visible: SettingsService.sideCfg("entries", "power")
                onHoverStarted: SideState.sessionHover = true
                onHoverEnded: SideState.sessionHover = false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.railSize
                Layout.preferredHeight: root.railSize
                size: root.railSize
                icon: "power"
                iconSize: Constants.sizeXl
                active: AppState.isWidgetOpen("powerMenu")
                onClicked: AppState.toggleWidget("powerMenu")

                SidePill {
                    z: -1
                    anchors.fill: parent
                    radius: width / 2
                }
            }
        }
    }

    // hovered or busy: stays open while a panel or popout belongs to the bar
    property bool keepOpen: false
    // workspaces pop in for a moment after a switch, then the capsule goes back to its idle view
    property bool peek: false
    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    onActiveWsChanged: {
        if (root.shown && root.idleView !== "workspaces") {
            root.peek = true;
            transientTimer.restart();
        }
    }

    Timer {
        id: transientTimer

        interval: 2200
        onTriggered: root.peek = false
    }
}

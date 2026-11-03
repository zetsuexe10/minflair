import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Floating bar on the left, right, top or bottom edge (Settings > Bar): launcher, workspaces, window title, tray, status,
// clock and power. The window stays mapped for the whole session and only activates for the
// "side" style (destroying layer surfaces on a style switch can crash Quickshell).
PanelWindow {
    id: root

    required property var notificationService

    readonly property string position: SettingsService.sideBarPosition
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int railSize: SideState.railSize
    readonly property int barWidth: SideState.barThickness     // thickness of the bar strip, whichever the edge
    readonly property int edge: Math.round((barWidth - railSize) / 2)
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && !DisplayProfileService.gameModeActive
    readonly property bool fullscreen: HyprlandService.isTrueFullscreen
    readonly property bool shown: isActive && !fullscreen
    // how far the rail is pushed off-screen while hidden
    readonly property real hideShift: shown ? 0 : -(barWidth)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-side-bar"
    readonly property bool island: SideState.island
    readonly property string align: SideState.islandAlign
    readonly property real islandLen: (content.item ? (vertical ? content.item.implicitHeight : content.item.implicitWidth) : 0) + 16

    WlrLayershell.exclusiveZone: shown ? (island ? 0 : barWidth) : 0
    color: "transparent"
    focusable: false
    visible: SettingsService.settingsLoaded
    implicitWidth: vertical ? barWidth : (island ? islandLen : 0)
    implicitHeight: vertical ? (island ? islandLen : 0) : barWidth

    anchors {
        top: root.vertical ? (!root.island || root.align === "start") : root.position === "top"
        bottom: root.vertical ? (!root.island || root.align === "end") : root.position === "bottom"
        left: root.vertical ? root.position === "left" : (!root.island || root.align === "start")
        right: root.vertical ? root.position === "right" : (!root.island || root.align === "end")
    }

    // floating capsule: gap to the screen edge, offset along it
    margins {
        top: root.island ? (root.position === "top" ? SideState.islandGap - root.edge : (root.vertical && root.align === "start" ? SideState.islandOffset : 0)) : 0
        bottom: root.island ? (root.position === "bottom" ? SideState.islandGap - root.edge : (root.vertical && root.align === "end" ? SideState.islandOffset : 0)) : 0
        left: root.island ? (root.position === "left" ? SideState.islandGap - root.edge : (!root.vertical && root.align === "start" ? SideState.islandOffset : 0)) : 0
        right: root.island ? (root.position === "right" ? SideState.islandGap - root.edge : (!root.vertical && root.align === "end" ? SideState.islandOffset : 0)) : 0
    }

    // only the rail itself takes input
    mask: Region {
        Region {
            x: root.island ? rail.x + pill.x : 0
            y: root.island ? rail.y + pill.y : 0
            width: (root.island && root.shown) ? pill.width : 0
            height: (root.island && root.shown) ? pill.height : 0
        }

        Region {
            x: root.position === "right" ? root.width - root.barWidth + root.edge : (root.vertical ? root.edge : 0)
            y: root.position === "bottom" ? root.height - root.barWidth + root.edge : (root.vertical ? 0 : root.edge)
            width: (!root.shown || root.island) ? 0 : (root.vertical ? root.railSize : root.width)
            height: (!root.shown || root.island) ? 0 : (root.vertical ? root.height : root.railSize)
        }
    }

    Item {
        id: rail

        // slide towards the screen edge when hidden
        property real slide: root.shown ? 0 : root.hideShift

        x: root.vertical ? (root.position === "left" ? root.edge + slide : root.width - root.edge - root.railSize - slide) : 0
        y: root.vertical ? 0 : (root.position === "top" ? root.edge + slide : root.height - root.edge - root.railSize - slide)
        width: root.vertical ? root.railSize : parent.width
        height: root.vertical ? parent.height : root.railSize
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01

        Behavior on slide { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }

        // Like Caelestia: scrolling anywhere on the bar changes volume on the first half and
        // brightness on the second. Items that handle wheel themselves (workspaces, icons) win.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                const frac = root.vertical ? wheel.y / height : wheel.x / width;
                const dir = wheel.angleDelta.y > 0 ? 1 : -1;
                // first half: volume, second half: brightness (as in Caelestia)
                if (frac < 0.5) {
                    if (SettingsService.sideCfg("scroll", "volume"))
                        SideState.nudgeVolume(dir);
                } else if (SettingsService.sideCfg("scroll", "brightness") && SideState.brightnessAvailable) {
                    SideState.nudgeBrightness(dir);
                }
            }
        }

        // Island mode: a round capsule that shows the launcher and workspaces and grows to the
        // full bar while hovered. The window keeps its full length; only the capsule changes.
        Item {
            id: pill

            readonly property bool islandMode: root.island
            readonly property real total: root.vertical ? rail.height : rail.width
            readonly property real fullLen: root.islandLen
            readonly property real compactLen: Math.min(fullLen, 212)
            property bool expanded: false
            property real len: islandMode ? (expanded ? fullLen : compactLen) : total

            function along() {
                return root.align === "end" ? total - len : (root.align === "center" ? (total - len) / 2 : 0);
            }

            x: root.vertical ? 0 : (islandMode ? along() : 0)
            y: root.vertical ? (islandMode ? along() : 0) : 0
            width: root.vertical ? parent.width : len
            height: root.vertical ? len : parent.height
            clip: islandMode

            Behavior on len { SpringAnimation { spring: 2.6; damping: 0.32; epsilon: 0.5 } }

            HoverHandler {
                id: pillHover

                enabled: pill.islandMode
                onHoveredChanged: {
                    if (hovered) {
                        collapseTimer.stop();
                        pill.expanded = true;
                    } else {
                        collapseTimer.restart();
                    }
                }
            }

            Timer {
                id: collapseTimer

                interval: 500
                onTriggered: {
                    if (SideState.popout !== "" || AppState.activeWidget !== "")
                        restart();
                    else
                        pill.expanded = false;
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: pill.islandMode
                radius: Math.min(width, height) / 2
                color: SideState.surface
                border.width: 1
                border.color: SideState.outline
            }

            Loader {
                id: content

                x: 0
                y: 0
                width: pill.islandMode && !root.vertical ? root.islandLen : parent.width
                height: pill.islandMode && root.vertical ? root.islandLen : parent.height
                active: root.isActive

                sourceComponent: GridLayout {
                    anchors.fill: parent
                    anchors.topMargin: root.vertical ? (root.island ? 8 : 12) : 0
                    anchors.bottomMargin: root.vertical ? (root.island ? 8 : 12) : 0
                    anchors.leftMargin: root.vertical ? 0 : (root.island ? 8 : 12)
                    anchors.rightMargin: root.vertical ? 0 : (root.island ? 8 : 12)
                    flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                    rows: root.vertical ? 99 : 1
                    columns: root.vertical ? 1 : 99
                    rowSpacing: 6
                    columnSpacing: 6

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
                        visible: SettingsService.sideCfg("entries", "activeWindow") && !root.island
                        vertical: root.vertical
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillHeight: root.vertical
                        Layout.fillWidth: !root.vertical
                        Layout.preferredWidth: root.vertical ? root.railSize : -1
                        Layout.preferredHeight: root.vertical ? -1 : root.railSize
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

                    // pushes the sections above to the start when the window title is turned off
                    Item {
                        visible: !SettingsService.sideCfg("entries", "activeWindow")
                        Layout.fillHeight: root.vertical
                        Layout.fillWidth: !root.vertical
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
        }
    }
}

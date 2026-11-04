import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

PanelWindow {
    id: root

    required property var notificationService

    readonly property string position: SettingsService.sideBarPosition
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int railSize: SideState.railSize
    readonly property int barWidth: SideState.barThickness
    readonly property int edge: Math.round((barWidth - railSize) / 2)
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && !DisplayProfileService.gameModeActive
    readonly property bool fullscreen: HyprlandService.isTrueFullscreen
    readonly property bool shown: isActive && !fullscreen
    readonly property real hideShift: shown ? 0 : -(barWidth)

    readonly property bool dynamic: SettingsService.sideCfg("dynamic")
    readonly property bool hoverExpand: SettingsService.sideCfg("hover", "dynamic")
    readonly property bool expanded: !dynamic || SettingsService.sideCfg("pinned") || hold
    property bool hold: false
    property bool relayouting: false
    property int healed: 0

    function relayout() {
        relayouting = true;
        settle.restart();
    }

    Timer {
        id: release

        interval: 700
        onTriggered: root.hold = false
    }

    onDynamicChanged: {
        hold = false;
        relayout();
    }

    Timer {
        id: settle

        interval: 160
        onTriggered: root.relayouting = false
    }

    Connections {
        target: SideState

        function onFrameChanged() { root.relayout(); }
        function onBorderChanged() { root.relayout(); }
    }

    Connections {
        target: SettingsService

        function onSideBarPositionChanged() { root.relayout(); }
    }

    onHeightChanged: if (isActive) relayout()
    onWidthChanged: if (isActive) relayout()

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-side-bar"

    WlrLayershell.exclusiveZone: shown ? barWidth : 0
    color: "transparent"
    focusable: false
    visible: SettingsService.settingsLoaded
    implicitWidth: vertical ? barWidth : 0
    implicitHeight: vertical ? 0 : barWidth

    anchors {
        top: root.vertical || root.position === "top"
        bottom: root.vertical || root.position === "bottom"
        left: !root.vertical || root.position === "left"
        right: !root.vertical || root.position === "right"
    }

    mask: Region {
        x: (root.position === "right" ? root.width - root.barWidth + root.edge : (root.vertical ? root.edge : 0)) + (!root.expanded && !root.vertical ? dyn.x : 0)
        y: (root.position === "bottom" ? root.height - root.barWidth + root.edge : (root.vertical ? 0 : root.edge)) + (!root.expanded && root.vertical ? dyn.y : 0)
        width: !root.shown ? 0 : (root.expanded ? (root.vertical ? root.railSize : root.width) : (root.vertical ? root.railSize : dyn.width))
        height: !root.shown ? 0 : (root.expanded ? (root.vertical ? root.height : root.railSize) : (root.vertical ? dyn.height : root.railSize))
    }

    Item {
        id: rail

        property real slide: root.shown ? 0 : root.hideShift

        x: root.vertical ? (root.position === "left" ? root.edge + slide : root.width - root.edge - root.railSize - slide) : 0
        y: root.vertical ? 0 : (root.position === "top" ? root.edge + slide : root.height - root.edge - root.railSize - slide)
        width: root.vertical ? root.railSize : parent.width
        height: root.vertical ? parent.height : root.railSize
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01

        Behavior on slide { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    release.stop();
                    if (root.hoverExpand)
                        root.hold = true;
                } else {
                    release.restart();
                }
            }
        }

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

        Loader {
            id: content

            anchors.fill: parent
            active: root.isActive && !root.relayouting
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

            sourceComponent: GridLayout {
                id: grid

                function overflow() {
                    const r = root.vertical ? childrenRect.y + childrenRect.height : childrenRect.x + childrenRect.width;
                    const limit = root.vertical ? height : width;
                    const screenW = root.screen ? root.screen.width : root.width;
                    return r > limit + 1 || (!root.vertical && root.width > screenW + 1);
                }

                anchors.fill: parent
                anchors.topMargin: root.vertical ? 12 : 0
                anchors.bottomMargin: root.vertical ? 12 : 0
                anchors.leftMargin: root.vertical ? 0 : 12
                anchors.rightMargin: root.vertical ? 0 : 12
                flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                rows: root.vertical ? 99 : 1
                columns: root.vertical ? 1 : 99
                rowSpacing: 6
                columnSpacing: 6

                Timer {
                    interval: 250
                    repeat: true
                    running: root.shown
                    onTriggered: {
                        if (grid.overflow()) {
                            if (root.healed < 8) {
                                root.healed++;
                                root.relayout();
                            }
                        } else {
                            root.healed = 0;
                        }
                    }
                }

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

        MouseArea {
            x: dyn.x
            y: dyn.y
            width: dyn.width
            height: dyn.height
            enabled: root.dynamic && !root.expanded
            onClicked: {
                release.restart();
                root.hold = true;
            }
        }

        GridLayout {
            id: dyn

            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: root.vertical ? 99 : 1
            columns: root.vertical ? 1 : 99
            rowSpacing: 6
            columnSpacing: 6
            leftPadding: 6
            rightPadding: 6
            topPadding: 6
            bottomPadding: 6
            opacity: root.expanded ? 0 : 1
            scale: root.expanded ? 0.94 : 1
            visible: root.dynamic && opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

            SideWorkspaces {
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideClock {
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideMusicChip {
                id: chip

                visible: active
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
                onHoverChanged: (on) => SideState.musicHover = on
            }

            Binding {
                target: SideState
                property: "musicCenter"
                value: chip.visible ? (root.vertical ? rail.y + dyn.y + chip.y + chip.height / 2 : rail.x + dyn.x + chip.x + chip.width / 2) : -1
            }
        }
    }
}

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
        x: root.position === "right" ? root.width - root.barWidth + root.edge : (root.vertical ? root.edge : 0)
        y: root.position === "bottom" ? root.height - root.barWidth + root.edge : (root.vertical ? 0 : root.edge)
        width: !root.shown ? 0 : (root.vertical ? root.railSize : root.width)
        height: !root.shown ? 0 : (root.vertical ? root.height : root.railSize)
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
            active: root.isActive

            sourceComponent: GridLayout {
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
    }
}

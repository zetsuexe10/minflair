import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Floating vertical bar on the left edge: launcher, workspaces, window title, tray, status,
// clock and power. The window stays mapped for the whole session and only activates for the
// "side" style (destroying layer surfaces on a style switch can crash Quickshell).
PanelWindow {
    id: root

    required property var notificationService

    readonly property int railWidth: 48
    readonly property int edge: 8
    readonly property int barWidth: railWidth + edge * 2
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && !DisplayProfileService.gameModeActive
    readonly property bool fullscreen: HyprlandService.isTrueFullscreen
    readonly property bool shown: isActive && !fullscreen

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-side-bar"
    WlrLayershell.exclusiveZone: shown ? barWidth : 0
    color: "transparent"
    focusable: false
    visible: SettingsService.settingsLoaded
    implicitWidth: barWidth

    anchors {
        top: true
        bottom: true
        left: true
    }

    mask: Region {
        Region {
            x: root.edge
            y: 0
            width: root.shown ? root.railWidth : 0
            height: root.shown ? root.height : 0
        }
    }

    Item {
        id: rail

        x: root.edge - (root.shown ? 0 : root.barWidth)
        width: root.railWidth
        height: parent.height
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01

        Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }

        Loader {
            anchors.fill: parent
            active: root.isActive

            sourceComponent: ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: root.edge
                anchors.bottomMargin: root.edge
                spacing: root.edge

                SideButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    size: 48
                    icon: "apps-filled"
                    iconColor: Theme.accent
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
                    Layout.alignment: Qt.AlignHCenter
                }

                SideActiveWindow {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.preferredWidth: 48
                }

                SideTray {
                    Layout.alignment: Qt.AlignHCenter
                }

                SideStatus {
                    Layout.alignment: Qt.AlignHCenter
                    notificationService: root.notificationService
                }

                SideClock {
                    Layout.alignment: Qt.AlignHCenter
                }

                SideButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    size: 48
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

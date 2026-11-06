import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Services
import qs.Modules.Bar.Styles.Side

PanelWindow {
    id: root

    readonly property bool shown: SettingsService.settingsLoaded && SettingsService.barStyle === "dynamic" && SettingsService.dynCfg("frame") === true && !DisplayProfileService.gameModeActive && !HyprlandService.isTrueFullscreen
    readonly property int gap: 8
    readonly property int pillH: 32
    readonly property real barBand: gap + pillH + 6

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-dynamic-frame"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: false
    visible: SettingsService.settingsLoaded

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {}

    SideFrameShape {
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        insetLeft: SideState.border
        insetRight: SideState.border
        insetTop: root.barBand
        insetBottom: SideState.border
        rounding: SideState.rounding
        fill: SideState.surface

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
    }
}

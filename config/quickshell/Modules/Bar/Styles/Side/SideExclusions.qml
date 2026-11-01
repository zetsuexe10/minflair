import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Services

// Reserves the frame's thickness on the three edges that do not carry the bar, so tiled windows
// stop at the frame like they do at the bar.
Scope {
    id: root

    readonly property bool active: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && SideState.frame && !DisplayProfileService.gameModeActive && !HyprlandService.isTrueFullscreen

    Variants {
        // fixed set of windows (never created or destroyed on a position change)
        model: ["left", "right", "top", "bottom"]

        PanelWindow {
            id: win

            required property string modelData
            readonly property bool vertical: modelData === "left" || modelData === "right"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "minflair-side-exclusion-" + modelData
            WlrLayershell.exclusiveZone: (root.active && modelData !== SideState.position) ? SideState.border : 0
            color: "transparent"
            focusable: false
            visible: SettingsService.settingsLoaded
            implicitWidth: vertical ? 1 : 0
            implicitHeight: vertical ? 0 : 1
            mask: Region {}

            anchors {
                left: win.modelData !== "right"
                right: win.modelData !== "left"
                top: win.modelData !== "bottom"
                bottom: win.modelData !== "top"
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Services

// The screen frame of the side style: a solid border around the whole screen with rounded inner
// corners, thick on the bar's edge. Panels grow out of it. Click-through; it only draws.
PanelWindow {
    id: root

    readonly property bool shown: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && SideState.frame && !DisplayProfileService.gameModeActive && !HyprlandService.isTrueFullscreen

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-side-frame"
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

    // empty mask: every input event goes to what is underneath
    mask: Region {}

    SideFrameShape {
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        insetLeft: SideState.inset("left")
        insetRight: SideState.inset("right")
        insetTop: SideState.inset("top")
        insetBottom: SideState.inset("bottom")
        rounding: SideState.rounding
        fill: Theme.opaqueBg

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
    }
}

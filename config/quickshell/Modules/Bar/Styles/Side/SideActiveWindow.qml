import QtQuick
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Fills the free space of the bar with the focused window's title: rotated along a vertical bar,
// plain text on a horizontal one. The capsule is only as long as the title needs.
Item {
    id: root

    property bool vertical: true
    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: SettingsService.sideBarWindowTitle && toplevel ? (toplevel.title || toplevel.appId || "") : ""
    readonly property real wanted: metrics.width + 36
    readonly property real space: vertical ? height : width
    readonly property bool shown: title !== "" && space >= 96

    implicitWidth: 48
    implicitHeight: 48

    TextMetrics {
        id: metrics

        text: root.title
        font.family: Constants.fontFamily
        font.pixelSize: Math.round(12 * SettingsService.fontScale)
    }

    SidePill {
        anchors.left: parent.left
        anchors.top: parent.top
        width: root.vertical ? 48 : Math.max(72, Math.min(root.width, root.wanted))
        height: root.vertical ? Math.max(72, Math.min(root.height, root.wanted)) : 48
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        clip: true

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on width { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

        ThemedText {
            anchors.centerIn: parent
            width: (root.vertical ? parent.height : parent.width) - 28
            rotation: root.vertical ? -90 : 0
            text: root.title
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            customSize: 12
            color: Theme.muted
            maximumLineCount: 1
        }
    }
}

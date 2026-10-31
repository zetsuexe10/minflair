import QtQuick
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Fills the free space of the bar. Shows the focused window's title, written bottom-to-top, in a
// capsule that is only as long as the title needs.
Item {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: toplevel ? (toplevel.title || toplevel.appId || "") : ""
    readonly property real wanted: metrics.width + 36
    readonly property bool shown: title !== "" && height >= 96

    implicitWidth: 48

    TextMetrics {
        id: metrics

        text: root.title
        font.family: Constants.fontFamily
        font.pixelSize: Math.round(12 * SettingsService.fontScale)
    }

    SidePill {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 48
        height: Math.max(72, Math.min(parent.height, root.wanted))
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        clip: true

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on height { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

        ThemedText {
            anchors.centerIn: parent
            width: parent.height - 28
            rotation: -90
            text: root.title
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            customSize: 12
            color: Theme.muted
            maximumLineCount: 1
        }
    }
}

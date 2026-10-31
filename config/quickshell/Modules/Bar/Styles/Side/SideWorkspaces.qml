import QtQuick
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Vertical workspace switcher with a sliding active indicator.
SidePill {
    id: root

    readonly property int slot: 32
    readonly property int gap: 4
    readonly property int pad: 8
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int highestOccupied: {
        let maxId = 1;
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            if (ws && ws.id > maxId && ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0)
                maxId = ws.id;
        }
        return maxId;
    }
    readonly property int shown: Math.min(SettingsService.numberOfWorkspaces, Math.max(activeWsId, highestOccupied, 4))

    function occupied(id) {
        const list = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            if (ws && ws.id === id)
                return ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0;
        }
        return false;
    }

    function go(id) {
        if (id >= 1 && id <= SettingsService.numberOfWorkspaces)
            Hyprland.dispatch('hl.dsp.focus({workspace=' + id + '})');
    }

    implicitWidth: 48
    implicitHeight: shown * slot + (shown - 1) * gap + pad * 2

    Behavior on implicitHeight { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

    Rectangle {
        id: indicator

        x: root.pad + (root.width - root.pad * 2 - root.slot) / 2 - 0
        y: root.pad + (Math.min(root.activeWsId, root.shown) - 1) * (root.slot + root.gap)
        width: root.slot
        height: root.slot
        radius: width / 2
        color: Theme.accent

        Behavior on y { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pad
        spacing: root.gap

        Repeater {
            model: root.shown

            Item {
                id: wsItem

                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: wsId === root.activeWsId
                readonly property bool isOccupied: root.occupied(wsId)

                width: root.slot
                height: root.slot

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.bgSecondary
                    opacity: (!wsItem.isActive && hover.containsMouse) ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                }

                ThemedText {
                    anchors.centerIn: parent
                    visible: wsItem.isActive || wsItem.isOccupied
                    text: wsItem.wsId
                    customSize: 13
                    font.bold: true
                    color: wsItem.isActive ? Theme.opaqueBg : Theme.fg
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: !wsItem.isActive && !wsItem.isOccupied
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.muted
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(wsItem.wsId)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => root.go(root.activeWsId + (wheel.angleDelta.y > 0 ? -1 : 1))
    }
}

import QtQuick
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Workspace switcher with a sliding active indicator (vertical or horizontal).
SidePill {
    id: root

    property bool vertical: true
    readonly property int slot: 28
    readonly property int gap: 4
    readonly property int pad: 6
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // fixed number of slots: scrolling never changes the bar length, the window of ids follows the active one
    readonly property int shown: Math.min(SettingsService.numberOfWorkspaces, 5)
    readonly property int first: Math.max(1, Math.min(SettingsService.numberOfWorkspaces - shown + 1, activeWsId - Math.floor(shown / 2)))
    readonly property real along: shown * slot + (shown - 1) * gap + pad * 2

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

    implicitWidth: vertical ? 44 : along
    implicitHeight: vertical ? along : 44


    Rectangle {
        readonly property real offset: root.pad + (Math.max(0, Math.min(root.shown - 1, root.activeWsId - root.first))) * (root.slot + root.gap)

        x: root.vertical ? (root.width - root.slot) / 2 : offset
        y: root.vertical ? offset : (root.height - root.slot) / 2
        width: root.slot
        height: root.slot
        radius: width / 2
        color: Theme.accent

        Behavior on x { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on y { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    }

    Grid {
        x: root.vertical ? (root.width - width) / 2 : root.pad
        y: root.vertical ? root.pad : (root.height - height) / 2
        columns: root.vertical ? 1 : 99
        spacing: root.gap

        Repeater {
            model: root.shown

            Item {
                id: wsItem

                required property int index
                readonly property int wsId: root.first + index
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

import QtQuick
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Workspace switcher with a sliding active indicator (vertical or horizontal).
SidePill {
    id: root

    property bool vertical: true
    readonly property int slot: 24
    readonly property int gap: 4
    readonly property int pad: 5
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

    implicitWidth: vertical ? SideState.railSize : along
    implicitHeight: vertical ? along : SideState.railSize


    // Stretchy indicator: the leading edge moves first, the trailing edge catches up.
    // Own fixed durations so it animates even when the global animation factor is 0.
    readonly property real step: slot + gap
    readonly property real target: pad + Math.max(0, Math.min(shown - 1, activeWsId - first)) * step
    property real edgeA: target
    property real edgeB: target + slot
    Behavior on edgeA { NumberAnimation { duration: root.edgeA > root.target ? 150 : 260; easing.type: Easing.OutCubic } }
    Behavior on edgeB { NumberAnimation { duration: root.edgeB > root.target + root.slot ? 260 : 150; easing.type: Easing.OutCubic } }
    onTargetChanged: { edgeA = target; edgeB = target + slot; }

    Rectangle {
        x: root.vertical ? (root.width - root.slot) / 2 : root.edgeA
        y: root.vertical ? root.edgeA : (root.height - root.slot) / 2
        width: root.vertical ? root.slot : root.edgeB - root.edgeA
        height: root.vertical ? root.edgeB - root.edgeA : root.slot
        radius: root.slot / 2
        color: SideState.primary
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
                scale: hover.pressed ? 0.86 : (hover.containsMouse ? 1.14 : 1)

                Behavior on scale { SpringAnimation { spring: 3.4; damping: 0.3; epsilon: 0.002 } }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: SideState.card
                    opacity: (!wsItem.isActive && hover.containsMouse) ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                }

                SideText {
                    anchors.centerIn: parent
                    visible: wsItem.isActive || wsItem.isOccupied
                    text: wsItem.wsId
                    customSize: 13
                    font.bold: true
                    color: wsItem.isActive ? SideState.surface : SideState.fg

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: !wsItem.isActive && !wsItem.isOccupied
                    width: 6
                    height: 6
                    radius: 3
                    color: SideState.muted
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
        enabled: SettingsService.sideCfg("scroll", "workspaces")
        onWheel: (wheel) => root.go(root.activeWsId + (wheel.angleDelta.y > 0 ? -1 : 1))
    }
}

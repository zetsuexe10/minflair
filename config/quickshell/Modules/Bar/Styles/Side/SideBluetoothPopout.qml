import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Core
import qs.Core.Components

// Bluetooth panel: power switch and the paired/known devices with connect / disconnect.
ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: {
        const out = [];
        const list = (adapter && adapter.devices) ? adapter.devices.values : [];
        for (let i = 0; i < list.length; i++)
            if (list[i] && (list[i].paired || list[i].connected || list[i].bonded))
                out.push(list[i]);
        out.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0));
        return out;
    }

    implicitWidth: 300
    spacing: Constants.sizeSm

    RowLayout {
        Layout.fillWidth: true

        SideText {
            Layout.fillWidth: true
            text: "Bluetooth"
            font.bold: true
            customSize: Constants.sizeMd
        }

        Rectangle {
            id: sw

            implicitWidth: 44
            implicitHeight: 24
            radius: 12
            color: (root.adapter && root.adapter.enabled) ? SideState.primary : SideState.card
            border.width: 1
            border.color: SideState.outline

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                y: 3
                x: (root.adapter && root.adapter.enabled) ? parent.width - width - 3 : 3
                color: (root.adapter && root.adapter.enabled) ? SideState.surface : SideState.fg

                Behavior on x { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
            }

            TapHandler {
                onTapped: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
            }
        }
    }

    SideText {
        visible: root.adapter && root.adapter.enabled && root.devices.length === 0
        text: "No paired devices"
        color: SideState.muted
    }

    SideText {
        visible: root.adapter && !root.adapter.enabled
        text: "Bluetooth is off"
        color: SideState.muted
    }

    Repeater {
        model: (root.adapter && root.adapter.enabled) ? root.devices : []

        Rectangle {
            id: row

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 40
            radius: 12
            color: modelData.connected ? SideState.selected : (hover.hovered ? SideState.card : "transparent")

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                SideText {
                    Layout.fillWidth: true
                    text: row.modelData.name || row.modelData.deviceName || "Device"
                    elide: Text.ElideRight
                }

                SideText {
                    text: row.modelData.connected ? "Connected" + (row.modelData.batteryAvailable ? " · " + Math.round(row.modelData.battery * 100) + "%" : "") : "Not connected"
                    customSize: 10
                    color: row.modelData.connected ? SideState.primary : SideState.muted
                }
            }

            HoverHandler {
                id: hover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    if (row.modelData.connected)
                        row.modelData.disconnect();
                    else
                        row.modelData.connect();
                }
            }
        }
    }
}

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

        ThemedText {
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
            color: (root.adapter && root.adapter.enabled) ? Theme.accent : Theme.bgSecondary
            border.width: 1
            border.color: Theme.border

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                y: 3
                x: (root.adapter && root.adapter.enabled) ? parent.width - width - 3 : 3
                color: (root.adapter && root.adapter.enabled) ? Theme.opaqueBg : Theme.fg

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

    ThemedText {
        visible: root.adapter && root.adapter.enabled && root.devices.length === 0
        text: "No paired devices"
        color: Theme.muted
    }

    ThemedText {
        visible: root.adapter && !root.adapter.enabled
        text: "Bluetooth is off"
        color: Theme.muted
    }

    Repeater {
        model: (root.adapter && root.adapter.enabled) ? root.devices : []

        Rectangle {
            id: row

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 40
            radius: 12
            color: modelData.connected ? Theme.bgAccent : (hover.hovered ? Theme.bgSecondary : "transparent")

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                ThemedText {
                    Layout.fillWidth: true
                    text: row.modelData.name || row.modelData.deviceName || "Device"
                    elide: Text.ElideRight
                }

                ThemedText {
                    text: row.modelData.connected ? "Connected" + (row.modelData.batteryAvailable ? " · " + Math.round(row.modelData.battery * 100) + "%" : "") : "Not connected"
                    customSize: 10
                    color: row.modelData.connected ? Theme.accent : Theme.muted
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

import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Performance tab: one ring per resource with the numbers underneath.
Item {
    id: root

    implicitHeight: Math.round(300 * Math.max(1, SettingsService.fontScale))

    readonly property var items: [
        { "icon": "cpu", "name": "CPU", "v": SystemStats.cpuUsage, "a": SystemStats.cpuTemp, "b": SystemStats.cpuFreq, "c": 0 },
        { "icon": "cpu", "name": "GPU", "v": SystemStats.gpuUsage, "a": SystemStats.gpuTemp, "b": SystemStats.hasGpu ? SystemStats.gpuName : "no GPU", "c": 1, "show": SystemStats.hasGpu },
        { "icon": "memory", "name": "Memory", "v": SystemStats.memUsage, "a": SystemStats.memSizeText, "b": "", "c": 2 },
        { "icon": "disk", "name": "Storage", "v": SystemStats.disks.length > 0 ? SystemStats.disks[0].usage : 0, "a": SystemStats.disks.length > 0 ? SystemStats.disks[0].sizeText : "-", "b": SystemStats.disks.length > 0 ? SystemStats.disks[0].mount : "", "c": 3 }
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Repeater {
            model: root.items.length

            CaelCard {
                id: card

                required property int index
                readonly property var modelData: root.items[index]

                visible: modelData.show !== false
                Layout.fillWidth: true
                Layout.fillHeight: true
                corner: 30

                Column {
                    anchors.centerIn: parent
                    spacing: 14

                    CaelGauge {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 130
                        height: 130
                        stroke: 10
                        value: card.modelData.v / 100
                        fg: card.modelData.c === 0 ? SideState.primary : (card.modelData.c === 1 ? SideState.secondary : (card.modelData.c === 2 ? SideState.tertiary : Qt.darker(SideState.secondary, 1.1)))

                        Column {
                            anchors.centerIn: parent

                            SideText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.round(card.modelData.v) + "%"
                                customSize: 22
                                font.bold: true
                            }

                            SideText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: card.modelData.name
                                color: SideState.muted
                                customSize: 11
                            }
                        }
                    }

                    SideText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: card.modelData.a
                        font.bold: true
                    }

                    SideText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 150
                        horizontalAlignment: Text.AlignHCenter
                        text: card.modelData.b
                        color: SideState.muted
                        customSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

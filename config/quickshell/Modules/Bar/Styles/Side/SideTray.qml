import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Core
import qs.Core.Components

// Status-notifier tray: click activates, right click opens the menu next to the bar.
SidePill {
    id: root

    property bool vertical: true
    readonly property int count: SystemTray.items ? SystemTray.items.values.length : 0

    visible: count > 0
    implicitWidth: vertical ? SideState.railSize : grid.implicitWidth + 16
    implicitHeight: vertical ? grid.implicitHeight + 12 : SideState.railSize

    Grid {
        id: grid

        anchors.centerIn: parent
        columns: root.vertical ? 1 : 99
        spacing: 4

        Repeater {
            model: SystemTray.items

            Item {
                id: entry

                required property var modelData

                width: 26
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: SideState.card
                    opacity: area.containsMouse ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: entry.modelData.icon
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: (mouse) => {
                        const p = entry.mapToItem(null, root.vertical ? entry.width + 14 : 0, root.vertical ? 0 : entry.height + 14);
                        if (mouse.button === Qt.MiddleButton) {
                            entry.modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton || entry.modelData.onlyMenu) {
                            if (entry.modelData.hasMenu)
                                entry.modelData.display(QsWindow.window, p.x, p.y);
                        } else {
                            entry.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}

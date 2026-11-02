import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Notifications panel: do-not-disturb switch, unread count, clear and open the full center.
ColumnLayout {
    id: root

    required property var notificationService

    implicitWidth: 280
    spacing: Constants.sizeSm

    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            SideText {
                text: "Notifications"
                font.bold: true
                customSize: Constants.sizeMd
            }

            SideText {
                text: root.notificationService.unreadCount === 0 ? "All caught up" : root.notificationService.unreadCount + " in history"
                color: SideState.muted
                customSize: 10
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: 14
        color: root.notificationService.dndEnabled ? SideState.selected : SideState.card

        Behavior on color { ColorAnimation { duration: Constants.animFast } }

        SvgIcon {
            id: dndIcon

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            icon: root.notificationService.dndEnabled ? "bell-off" : "bell"
            iconColor: root.notificationService.dndEnabled ? SideState.primary : SideState.fg
            iconSize: Constants.sizeMd
            flat: true
        }

        SideText {
            anchors.left: dndIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Do not disturb"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 22
            radius: 11
            color: root.notificationService.dndEnabled ? SideState.primary : SideState.surface
            border.width: 1
            border.color: SideState.outline

            Rectangle {
                width: 16
                height: 16
                radius: 8
                y: 3
                x: root.notificationService.dndEnabled ? parent.width - width - 3 : 3
                color: root.notificationService.dndEnabled ? SideState.surface : SideState.fg

                Behavior on x { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.notificationService.dndEnabled = !root.notificationService.dndEnabled
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Constants.sizeSm

        Repeater {
            model: [
                { "label": "Open center", "act": "open" },
                { "label": "Clear all", "act": "clear" }
            ]

            Rectangle {
                id: btn

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 36
                radius: 12
                color: bh.hovered ? SideState.selected : SideState.card

                Behavior on color { ColorAnimation { duration: Constants.animFast } }

                SideText {
                    anchors.centerIn: parent
                    text: btn.modelData.label
                }

                HoverHandler {
                    id: bh

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (btn.modelData.act === "clear") {
                            root.notificationService.clearHistory();
                        } else {
                            SideState.close();
                            AppState.toggleWidget("notificationsCenter");
                        }
                    }
                }
            }
        }
    }
}

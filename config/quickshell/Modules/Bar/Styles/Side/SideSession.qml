import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components

// Power panel: big square buttons stacked on the edge. Destructive actions ask for a second click.
Column {
    id: root

    signal done()

    property int armed: -1
    readonly property var actions: [
        { "label": "Lock", "icon": "lock", "confirm": false, "command": ["sh", "-c", "sleep 0.3; socat - UNIX-CONNECT:/tmp/quickshell_lockScreen"] },
        { "label": "Log out", "icon": "logout", "confirm": true, "command": ["sh", "-c", "if command -v uwsm >/dev/null 2>&1 && uwsm check is-active 2>/dev/null; then uwsm stop; else hyprctl dispatch 'hl.dsp.exit()' || loginctl terminate-user \"\"; fi"] },
        { "label": "Suspend", "icon": "moon", "confirm": true, "command": ["sh", "-c", "mpc -q pause; amixer set Master mute; systemctl suspend"] },
        { "label": "Reboot", "icon": "reload", "confirm": true, "command": ["systemctl", "reboot"] },
        { "label": "Shut down", "icon": "power", "confirm": true, "command": ["systemctl", "poweroff"] }
    ]

    spacing: 10

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.armed = -1
    }

    Process {
        id: proc
    }

    Repeater {
        model: root.actions

        Rectangle {
            id: btn

            required property var modelData
            required property int index
            readonly property bool isArmed: root.armed === index

            width: 68
            height: 68
            radius: isArmed ? 20 : (hover.hovered ? 26 : 22)
            color: isArmed ? "#c0434d" : (hover.hovered ? Theme.bgAccent : Theme.bgSecondary)

            Behavior on color { ColorAnimation { duration: Constants.animFast } }
            Behavior on radius { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }

            SvgIcon {
                anchors.centerIn: parent
                icon: btn.modelData.icon
                iconSize: 26
                iconColor: btn.isArmed ? "#ffffff" : (hover.hovered ? Theme.accent : Theme.fg)
                flat: true
            }

            ThemedText {
                visible: btn.isArmed
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: "again"
                customSize: 9
                color: "#ffffff"
            }

            HoverHandler {
                id: hover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    if (btn.modelData.confirm && root.armed !== btn.index) {
                        root.armed = btn.index;
                        disarm.restart();
                        return ;
                    }
                    proc.command = btn.modelData.command;
                    proc.startDetached();
                    root.armed = -1;
                    root.done();
                }
            }
        }
    }
}

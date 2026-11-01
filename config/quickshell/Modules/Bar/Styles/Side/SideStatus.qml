import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Network, Bluetooth, volume, keyboard layout, lock keys and notifications. No battery.
SidePill {
    id: root

    required property var notificationService

    property bool vertical: true

    property bool wifiUp: false
    property bool ethUp: false
    property bool capsOn: false
    property bool numOn: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter ? adapter.enabled : false
    readonly property bool btConnected: {
        if (!adapter || !adapter.devices)
            return false;
        const list = adapter.devices.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].connected)
                return true;
        return false;
    }
    readonly property string layoutCode: (HyprlandService.keyboardLayout || "us").split(",")[0].substring(0, 2).toUpperCase()

    function cycleLayout() {
        const list = SettingsService.enabledKbLayouts || [];
        if (list.length < 2)
            return;
        const i = list.indexOf(HyprlandService.keyboardLayout);
        HyprlandService.keyboardLayout = list[(i + 1) % list.length];
    }

    function nudgeVolume(wheel) {
        SideState.nudgeVolume(wheel.angleDelta.y > 0 ? 1 : -1);
    }

    implicitWidth: vertical ? 44 : col.implicitWidth + 16
    implicitHeight: vertical ? col.implicitHeight + 12 : 44

    function centerOf(item) {
        const p = item.mapToItem(null, item.width / 2, item.height / 2);
        return vertical ? p.y : p.x;
    }

    Process {
        id: netProc

        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.wifiUp = lines.indexOf("wifi:connected") !== -1;
                root.ethUp = lines.indexOf("ethernet:connected") !== -1;
            }
        }
    }

    Process {
        id: lockProc

        command: ["sh", "-c", "c=0; n=0; for f in /sys/class/leds/*capslock/brightness; do [ \"$(cat \"$f\" 2>/dev/null)\" = 1 ] && c=1; done; for f in /sys/class/leds/*numlock/brightness; do [ \"$(cat \"$f\" 2>/dev/null)\" = 1 ] && n=1; done; echo $c$n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.capsOn = t.charAt(0) === "1";
                root.numOn = t.charAt(1) === "1";
            }
        }
    }

    Connections {
        target: SideState

        function onNetTickChanged() {
            netProc.running = false;
            netProc.running = true;
        }
    }

    Timer {
        interval: 10000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: lockProc.running = true
    }

    Grid {
        id: col

        anchors.centerIn: parent
        columns: root.vertical ? 1 : 99
        spacing: 2

        SideButton {
            visible: root.capsOn || root.numOn
            icon: root.capsOn ? "caps-lock-filled" : "keyboard-filled"
            iconColor: Theme.accent
            active: true
            iconSize: Constants.sizeMd
            onClicked: AppState.toggleWidget("controlCenter")
        }

        SideButton {
            id: netBtn

            icon: (root.wifiUp || root.ethUp) ? "wifi" : "wifi-off"
            iconColor: (root.wifiUp || root.ethUp) ? Theme.fg : Theme.muted
            iconSize: Constants.sizeMd
            active: SideState.popout === "network"
            onClicked: SideState.popout === "network" ? SideState.close() : SideState.open("network", root.centerOf(netBtn))
            onHoverStarted: SideState.hover("network", root.centerOf(netBtn))
            onHoverEnded: SideState.release()
        }

        SideButton {
            id: btBtn

            visible: root.adapter !== null
            icon: root.btOn ? "bluetooth" : "bluetooth-off"
            iconColor: root.btConnected ? Theme.accent : (root.btOn ? Theme.fg : Theme.muted)
            iconSize: Constants.sizeMd
            active: SideState.popout === "bluetooth"
            onClicked: SideState.popout === "bluetooth" ? SideState.close() : SideState.open("bluetooth", root.centerOf(btBtn))
            onHoverStarted: SideState.hover("bluetooth", root.centerOf(btBtn))
            onHoverEnded: SideState.release()
        }

        SideButton {
            id: volBtn

            icon: (root.muted || root.volume <= 0) ? "volume-off" : "volume"
            iconColor: root.muted ? Theme.muted : Theme.fg
            iconSize: Constants.sizeMd
            active: SideState.popout === "audio"
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton && root.sink && root.sink.audio)
                    root.sink.audio.muted = !root.sink.audio.muted;
                else
                    SideState.popout === "audio" ? SideState.close() : SideState.open("audio", root.centerOf(volBtn));
            }
            onScrolled: (wheel) => root.nudgeVolume(wheel)
            onHoverStarted: SideState.hover("audio", root.centerOf(volBtn))
            onHoverEnded: SideState.release()
        }

        SideButton {
            id: briBtn

            visible: SideState.brightnessAvailable
            icon: "sun"
            iconSize: Constants.sizeMd
            onClicked: SideState.popout === "audio" ? SideState.close() : SideState.open("audio", root.centerOf(briBtn))
            onScrolled: (wheel) => SideState.nudgeBrightness(wheel.angleDelta.y > 0 ? 1 : -1)
            onHoverStarted: SideState.hover("audio", root.centerOf(briBtn))
            onHoverEnded: SideState.release()
        }

        SideButton {
            visible: (SettingsService.enabledKbLayouts || []).length > 1
            label: root.layoutCode
            onClicked: root.cycleLayout()
        }

        SideButton {
            id: bellBtn

            onHoverStarted: SideState.hover("notifications", root.centerOf(bellBtn))
            onHoverEnded: SideState.release()
            icon: (root.notificationService && root.notificationService.dndEnabled) ? "bell-off" : "bell"
            iconColor: (root.notificationService && root.notificationService.unreadCount > 0) ? Theme.accent : Theme.fg
            iconSize: Constants.sizeMd
            active: AppState.isWidgetOpen("notificationsCenter")
            onClicked: AppState.toggleWidget("notificationsCenter")
        }
    }
}

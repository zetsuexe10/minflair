import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property int percent: 0
    property bool connected: false
    property string ssid: ""
    readonly property string stepIcon: percent <= 25 ? "wifi-0" : (percent <= 50 ? "wifi-1" : (percent <= 75 ? "wifi-2" : "wifi"))
    readonly property string icon: connected ? stepIcon : "wifi-off"

    function iconFor(sig) {
        const n = parseInt(sig) || 0;
        return n <= 25 ? "wifi-0" : (n <= 50 ? "wifi-1" : (n <= 75 ? "wifi-2" : "wifi"));
    }

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: proc

        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let found = false;
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("yes:") !== 0)
                        continue;
                    const parts = lines[i].split(":");
                    root.percent = parseInt(parts[1]) || 0;
                    root.ssid = parts.slice(2).join(":");
                    found = true;
                    break;
                }
                root.connected = found;
                if (!found)
                    root.percent = 0;
            }
        }
    }
}

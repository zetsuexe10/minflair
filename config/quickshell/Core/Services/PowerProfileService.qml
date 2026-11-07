pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string current: "balanced"
    property bool available: false
    readonly property var profiles: [
        { "id": "power-saver", "label": "Saver", "icon": "battery" },
        { "id": "balanced", "label": "Balanced", "icon": "gauge" },
        { "id": "performance", "label": "Performance", "icon": "zap" }
    ]

    function set(id) {
        setProc.command = ["powerprofilesctl", "set", id];
        setProc.running = true;
        current = id;
    }

    function refresh() {
        getProc.running = true;
    }

    Process {
        id: getProc

        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.available = t.length > 0;
                if (t.length > 0)
                    root.current = t;
            }
        }
    }

    Process {
        id: setProc

        onExited: root.refresh()
    }
}

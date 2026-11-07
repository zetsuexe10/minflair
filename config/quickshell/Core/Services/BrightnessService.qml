import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property int percent: 0
    readonly property string icon: "brightness-" + (Math.round(Math.max(0, Math.min(100, percent)) / 100 * 6) + 1)
    property bool available: false
    property int watchers: 0
    property int _pending: -1

    function refresh() {
        if (!getProc.running)
            getProc.running = true;
    }

    function set(pct) {
        const v = Math.max(1, Math.min(100, Math.round(pct)));
        root.percent = v;
        root._pending = v;
        if (!throttle.running)
            throttle.start();
    }

    function nudge(delta) {
        set(percent + delta);
    }

    Timer {
        id: throttle

        interval: 40
        onTriggered: {
            if (setProc.running) {
                throttle.restart();
                return;
            }
            setProc.command = ["brightnessctl", "set", root._pending + "%"];
            setProc.running = true;
        }
    }

    Timer {
        interval: 400
        running: root.watchers > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!throttle.running && !setProc.running)
                root.refresh();
        }
    }

    Process {
        id: getProc

        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                const pct = parseInt((f[3] || "").replace("%", ""));
                root.available = !isNaN(pct);
                if (!isNaN(pct))
                    root.percent = pct;
            }
        }
    }

    Process {
        id: setProc
    }

    Component.onCompleted: refresh()
}

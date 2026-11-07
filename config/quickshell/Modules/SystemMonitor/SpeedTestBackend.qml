import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string state: "idle"
    property real downMbps: 0
    property real upMbps: 0
    property real pingMs: -1
    property real progress: 0
    property real liveMbps: 0
    property string message: ""
    property var liveHistory: []
    property real lastDown: -1
    property real lastUp: -1
    property real lastPing: -1
    property string lastAt: ""
    property var history: []
    readonly property string historyFile: Quickshell.env("HOME") + "/.cache/minflair/speedtests.json"
    readonly property bool running: state === "latency" || state === "download" || state === "upload" || state === "starting"
    readonly property string script: Quickshell.shellDir + "/Modules/SystemMonitor/scripts/speedtest.py"

    function start() {
        if (running)
            return;
        state = "starting";
        downMbps = 0;
        upMbps = 0;
        pingMs = -1;
        progress = 0;
        liveMbps = 0;
        liveHistory = [];
        message = "";
        proc.running = true;
    }

    function stop() {
        if (proc.running)
            proc.signal(15);
        state = "idle";
    }

    function _line(raw) {
        let m;
        try {
            m = JSON.parse(raw);
        } catch (err) {
            return;
        }
        if (m.phase === "start") {
            state = "starting";
        } else if (m.phase === "latency") {
            state = "latency";
        } else if (m.phase === "latency_done") {
            pingMs = m.ping;
        } else if (m.phase === "download" || m.phase === "upload") {
            state = m.phase;
            liveMbps = m.mbps;
            progress = m.pct;
            const h = liveHistory.slice(-59);
            h.push(m.mbps);
            liveHistory = h;
            if (m.phase === "download")
                downMbps = m.mbps;
            else
                upMbps = m.mbps;
        } else if (m.phase === "download_done") {
            downMbps = m.mbps;
            liveHistory = [];
        } else if (m.phase === "done") {
            downMbps = m.down;
            upMbps = m.up === null || m.up === undefined ? 0 : m.up;
            pingMs = m.ping;
            lastDown = downMbps;
            lastUp = m.up === null || m.up === undefined ? -1 : m.up;
            lastPing = pingMs;
            lastAt = Qt.formatDateTime(new Date(), "h:mm AP");
            history = [{ "t": Date.now(), "down": downMbps, "up": upMbps, "ping": pingMs }].concat(history).slice(0, 8);
            saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", historyFile, JSON.stringify(history)];
            saveProc.running = true;
            state = "done";
        } else if (m.phase === "error") {
            message = m.message;
            state = "error";
        }
    }

    Process {
        id: saveProc
    }

    Process {
        id: loadProc

        command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "sh", root.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (Array.isArray(d) && d.length > 0) {
                        root.history = d.slice(0, 8);
                        if (root.lastDown < 0) {
                            root.lastDown = d[0].down;
                            root.lastUp = d[0].up > 0 ? d[0].up : -1;
                            root.lastPing = d[0].ping;
                        }
                    }
                } catch (err) {
                }
            }
        }
    }

    Component.onCompleted: loadProc.running = true

    Process {
        id: proc

        command: ["python3", root.script]
        stdout: SplitParser {
            onRead: data => root._line(data)
        }
        onExited: {
            if (root.running) {
                root.message = "The test stopped unexpectedly";
                root.state = "error";
            }
        }
    }
}
